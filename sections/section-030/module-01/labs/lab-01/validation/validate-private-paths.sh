#!/usr/bin/env bash
# PASS when /admin/, the master realm, /metrics and /health answer 403 or 404
# through nginx.
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

# Creates the self-signed certificate for keycloak.localtest.me in the tester
# pod (it has openssl) and stores it in the Secret edge-tls.
create_edge_tls() {
  if kubectl -n "$NAMESPACE" get secret edge-tls >/dev/null 2>&1; then
    return 0
  fi
  local work
  work="$(mktemp -d)"
  kubectl -n "$NAMESPACE" exec deploy/tester -- sh -c \
    'openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
       -subj "/CN=keycloak.localtest.me" \
       -addext "subjectAltName=DNS:keycloak.localtest.me" \
       -keyout /tmp/tls.key -out /tmp/tls.crt >/dev/null 2>&1'
  kubectl -n "$NAMESPACE" exec deploy/tester -- cat /tmp/tls.crt > "$work/tls.crt"
  kubectl -n "$NAMESPACE" exec deploy/tester -- cat /tmp/tls.key > "$work/tls.key"
  kubectl -n "$NAMESPACE" create secret tls edge-tls --cert="$work/tls.crt" --key="$work/tls.key"
  rm -rf "$work"
}

# Prints the ClusterIP of the nginx Service.
nginx_ip() {
  kubectl -n "$NAMESPACE" get service nginx -o jsonpath='{.spec.clusterIP}'
}

# proxy_curl PATH [CURL_ARGS...]: requests a path through nginx from the tester pod.
proxy_curl() {
  local request_path="$1"; shift
  kubectl -n "$NAMESPACE" exec deploy/tester -- curl -sk \
    --resolve "keycloak.localtest.me:8443:$(nginx_ip)" "$@" \
    "https://keycloak.localtest.me:8443$request_path"
}
for request_path in /admin/master/console/ /realms/master/.well-known/openid-configuration /metrics /health/ready; do
  CODE="$(proxy_curl "$request_path" -o /dev/null -w '%{http_code}' 2>/dev/null)"
  case "$CODE" in
    403|404) ;;
    *) echo "FAIL: $request_path answers $CODE through nginx; it must stay internal (403 or 404)."; exit 1 ;;
  esac
done
echo "PASS: the administration console, the master realm and the management endpoints are not reachable through nginx."
exit 0
