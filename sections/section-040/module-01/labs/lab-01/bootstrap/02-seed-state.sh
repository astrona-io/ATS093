#!/usr/bin/env bash
# Creates the starting state for ats-093-lab-040-01.
# 
# Applies Keycloak and imports the realm inventory, creates the realm
# restore-check, dumps the database to /backup/keycloak.dump in the postgres
# pod, and then deletes restore-check and the user alice from the live database.
# The restore is NOT done here: it is the task.
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

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

echo "[lab] Applying the Keycloak resource..."
kubectl apply -f "$MANIFESTS/keycloak.yaml"
wait_for_keycloak_ready || { echo "[lab] ERROR: Keycloak did not become Ready." >&2; exit 1; }

echo "[lab] Importing the realm inventory..."
kubectl apply -f "$MANIFESTS/realm-import-inventory.yaml"
for _ in $(seq 1 60); do
  [ "$(kubectl -n "$NAMESPACE" get keycloakrealmimport inventory -o jsonpath='{.status.conditions[?(@.type=="Done")].status}' 2>/dev/null)" = "True" ] && break
  sleep 5
done

# Creates the realm restore-check, which exists only to show whether a
# restore brought data back.
create_restore_check_realm() {
  kcadm_login
  kcadm get realms/restore-check >/dev/null 2>&1 || \
    kcadm create realms -s realm=restore-check -s enabled=true
}

echo "[lab] Creating the realm restore-check and taking the database dump..."
create_restore_check_realm
kubectl -n "$NAMESPACE" exec deploy/postgres -- pg_dump -U keycloak -d keycloak -Fc -f /backup/keycloak.dump
kubectl -n "$NAMESPACE" exec deploy/postgres -- ls -l /backup/keycloak.dump

echo "[lab] Losing data after the dump..."
kcadm delete realms/restore-check
ALICE_ID="$(kcadm get users -r inventory -q username=alice -q exact=true --fields id --format csv --noquotes | head -1)"
kcadm delete "users/$ALICE_ID" -r inventory
kcadm get realms --fields realm
echo "[lab] The realm restore-check and the user alice are gone from the live database. The dump in /backup still has them. Restoring is the task."
