#!/usr/bin/env bash
# PASS when no user credential in the realm import holds a literal password, and a
# placeholder reads the key alice-password of the Secret inventory-secrets.
set -uo pipefail

# --- shared helpers (same block in every ATS093 script) ---
NAMESPACE="keycloak"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://keycloak-service:8080}"

# Prints the status of one condition of the Keycloak resource "keycloak".
keycloak_condition() {
  kubectl -n "$NAMESPACE" get keycloak keycloak \
    -o jsonpath="{.status.conditions[?(@.type==\"$1\")].status}" 2>/dev/null || true
}

# Waits until the Keycloak resource reports Ready=True (up to ten minutes).
wait_for_keycloak_ready() {
  for _ in $(seq 1 120); do
    [ "$(keycloak_condition Ready)" = "True" ] && return 0
    sleep 5
  done
  return 1
}

# Runs kcadm.sh inside the first Keycloak pod.
kcadm() {
  kubectl -n "$NAMESPACE" exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}

# Signs kcadm.sh in to master with the operator's initial admin Secret.
kcadm_login() {
  local admin_user admin_password
  admin_user="$(kubectl -n "$NAMESPACE" get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)"
  admin_password="$(kubectl -n "$NAMESPACE" get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
  for _ in $(seq 1 30); do
    kcadm config credentials --server http://localhost:8080 --realm master \
      --user "$admin_user" --password "$admin_password" >/dev/null 2>&1 && return 0
    sleep 5
  done
  return 1
}

# Prints the token response for a password grant from the tester pod.
# user_token USER PASSWORD [BASE_URL] [EXTRA_CURL_ARGS...]
user_token() {
  local user="$1" password="$2" base="${3:-$KEYCLOAK_URL}"
  shift 3 2>/dev/null || shift $#
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s "$@" \
    "$base/realms/inventory/protocol/openid-connect/token" \
    -d grant_type=password -d client_id=inventory-cli \
    -d username="$user" -d password="$password" -d scope=openid
}

# Prints the payload of a JWT as JSON (runs jq in the tester pod).
jwt_payload() {
  printf '%s' "$1" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- \
    jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - (length % 4)) % 4)) | @base64d | fromjson'
}
# --- end of shared helpers ---

IMPORT="$(kubectl -n "$NAMESPACE" get keycloakrealmimport inventory -o json 2>/dev/null)"
if [ -z "$IMPORT" ]; then
  echo "FAIL: there is no KeycloakRealmImport named inventory."
  exit 1
fi
LITERALS="$(printf '%s' "$IMPORT" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- \
  jq -r '[.spec.realm.users[]?.credentials[]?.value | select(startswith("${") | not)] | length')"
SECRET_REFS="$(printf '%s' "$IMPORT" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- \
  jq -r '[.spec.placeholders // {} | to_entries[] | select(.value.secret.name == "inventory-secrets" and .value.secret.key == "alice-password")] | length')"
if [ "$LITERALS" != "0" ]; then
  echo "FAIL: a user credential in the realm import holds a literal value. Use a placeholder."
  exit 1
fi
if [ "$SECRET_REFS" = "0" ]; then
  echo "FAIL: no placeholder reads the key alice-password from the Secret inventory-secrets."
  exit 1
fi
echo "PASS: the realm import takes alice's password from the Secret through a placeholder."
exit 0
