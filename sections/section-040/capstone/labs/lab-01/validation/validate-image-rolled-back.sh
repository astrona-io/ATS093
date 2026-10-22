#!/usr/bin/env bash
# PASS when keycloak-0 runs the image quay.io/keycloak/keycloak:26.8.1 and the
# Keycloak resource is Ready.
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

EXPECTED_IMAGE="quay.io/keycloak/keycloak:26.8.1"
SPEC_IMAGE="$(kubectl -n "$NAMESPACE" get keycloak keycloak -o jsonpath='{.spec.image}')"
if [ -n "$SPEC_IMAGE" ] && [ "$SPEC_IMAGE" != "$EXPECTED_IMAGE" ]; then
  echo "FAIL: spec.image is $SPEC_IMAGE; remove it or set it to $EXPECTED_IMAGE."
  exit 1
fi
POD_IMAGE="$(kubectl -n "$NAMESPACE" get pod keycloak-0 -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)"
POD_READY="$(kubectl -n "$NAMESPACE" get pod keycloak-0 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$POD_IMAGE" != "$EXPECTED_IMAGE" ] || [ "$POD_READY" != "True" ]; then
  echo "FAIL: keycloak-0 is not a ready pod running $EXPECTED_IMAGE (image: ${POD_IMAGE:-none}, ready: ${POD_READY:-no})."
  exit 1
fi
if [ "$(keycloak_condition Ready)" != "True" ]; then
  echo "FAIL: the Keycloak resource is not Ready."
  exit 1
fi
echo "PASS: Keycloak runs $EXPECTED_IMAGE again."
exit 0
