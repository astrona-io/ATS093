#!/usr/bin/env bash
# PASS when the Keycloak resource requests at most 1Gi of memory per pod (so two
# pods fit on the node) and limits each pod to at least 1Gi.
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

# Converts a Kubernetes memory quantity (Ki, Mi, Gi, K, M, G or bytes) to MiB.
to_mib() {
  local quantity="$1"
  case "$quantity" in
    *Gi) echo $(( ${quantity%Gi} * 1024 )) ;;
    *Mi) echo "${quantity%Mi}" ;;
    *Ki) echo $(( ${quantity%Ki} / 1024 )) ;;
    *G)  echo $(( ${quantity%G} * 1000000000 / 1048576 )) ;;
    *M)  echo $(( ${quantity%M} * 1000000 / 1048576 )) ;;
    *K)  echo $(( ${quantity%K} * 1000 / 1048576 )) ;;
    "")  echo "" ;;
    *)   echo $(( quantity / 1048576 )) ;;
  esac
}
REQUEST="$(kubectl -n "$NAMESPACE" get keycloak keycloak -o jsonpath='{.spec.resources.requests.memory}')"
LIMIT="$(kubectl -n "$NAMESPACE" get keycloak keycloak -o jsonpath='{.spec.resources.limits.memory}')"
REQUEST_MIB="$(to_mib "$REQUEST")"
LIMIT_MIB="$(to_mib "$LIMIT")"
if [ -z "$REQUEST_MIB" ] || [ "$REQUEST_MIB" -gt 1024 ]; then
  echo "FAIL: set a memory request of at most 1Gi per pod (found: ${REQUEST:-none})."
  exit 1
fi
if [ -z "$LIMIT_MIB" ] || [ "$LIMIT_MIB" -lt 1024 ]; then
  echo "FAIL: set a memory limit of at least 1Gi per pod (found: ${LIMIT:-none})."
  exit 1
fi
echo "PASS: memory request $REQUEST and limit $LIMIT."
exit 0
