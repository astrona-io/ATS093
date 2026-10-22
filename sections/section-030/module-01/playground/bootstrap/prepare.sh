#!/usr/bin/env bash
# OS prep for the "Put Keycloak Behind A Reverse Proxy" playground (`ats-093-playground-030-01`).
# 
# Environment preparation only. There is no task and no grading. This script:
#   1. installs the Keycloak Operator 26.8.1, PostgreSQL and the tester pod,
#   2. applies a Keycloak resource set up for an edge proxy, and imports the
#      realm inventory with the users alice and bob,
#   3. creates a self-signed certificate and starts nginx in front of Keycloak.
# Brute force detection and the rate limit are left off: the module adds them.
set -euo pipefail

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

OPERATOR_VERSION="26.8.1"
BASE="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${OPERATOR_VERSION}/kubernetes"
NAMESPACE="keycloak"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

echo "[playground] Applying the namespace, PostgreSQL and the tester pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"

echo "[playground] Installing the Keycloak Operator ${OPERATOR_VERSION}..."
kubectl apply -f "$BASE/keycloaks.k8s.keycloak.org-v1.yml"
kubectl apply -f "$BASE/keycloakrealmimports.k8s.keycloak.org-v1.yml"
kubectl -n "$NAMESPACE" apply -f "$BASE/kubernetes.yml"
kubectl wait --for=condition=Established crd/keycloaks.k8s.keycloak.org --timeout=60s
kubectl wait --for=condition=Established crd/keycloakrealmimports.k8s.keycloak.org --timeout=60s

kubectl -n "$NAMESPACE" rollout status deployment/keycloak-operator --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/postgres --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s
echo "[playground] Operator, PostgreSQL and tester ready."

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

# Applies a Keycloak resource, the realm import with alice and bob, the TLS
# certificate and nginx with the given configuration.
# apply_edge KEYCLOAK_FILE NGINX_CONF_FILE
apply_edge() {
  echo "[setup] Applying the Keycloak resource..."
  kubectl apply -f "$1"
  wait_for_keycloak_ready || { echo "[setup] ERROR: Keycloak did not become Ready." >&2; exit 1; }

  echo "[setup] Importing the realm inventory..."
  kubectl apply -f "$MANIFEST_DIR/realm-import-inventory.yaml"
  for _ in $(seq 1 60); do
    [ "$(kubectl -n "$NAMESPACE" get keycloakrealmimport inventory -o jsonpath='{.status.conditions[?(@.type=="Done")].status}' 2>/dev/null)" = "True" ] && break
    sleep 5
  done

  echo "[setup] Creating the edge certificate and starting nginx..."
  create_edge_tls
  kubectl apply -f "$2"
  kubectl apply -f "$MANIFEST_DIR/nginx-edge.yaml"
  kubectl -n "$NAMESPACE" rollout status deployment/nginx --timeout=300s
}

apply_edge "$MANIFEST_DIR/keycloak.yaml" "$MANIFEST_DIR/nginx-conf.yaml"

echo "[playground] Ready."
kubectl -n keycloak get keycloak,deployment,pods
echo "[playground] Keycloak answers through nginx at https://keycloak.localtest.me:8443 (self-signed certificate)."
