#!/usr/bin/env bash
# OS prep for the "Run Keycloak As A Cluster" playground (`ats-093-playground-020-01`).
# 
# Environment preparation only. There is no task and no grading. This script:
#   1. installs the Keycloak Operator 26.8.1, PostgreSQL and the tester pod,
#   2. applies a Keycloak resource with two instances and waits until it is Ready,
#   3. imports the realm inventory with a KeycloakRealmImport.
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
kubectl apply -f "$BASE/keycloakoidcclients.k8s.keycloak.org-v1.yml"
kubectl apply -f "$BASE/keycloaksamlclients.k8s.keycloak.org-v1.yml"
kubectl -n "$NAMESPACE" apply -f "$BASE/kubernetes.yml"
kubectl wait --for=condition=Established crd/keycloaks.k8s.keycloak.org --timeout=60s
kubectl wait --for=condition=Established crd/keycloakrealmimports.k8s.keycloak.org --timeout=60s
kubectl wait --for=condition=Established crd/keycloakoidcclients.k8s.keycloak.org --timeout=60s
kubectl wait --for=condition=Established crd/keycloaksamlclients.k8s.keycloak.org --timeout=60s

kubectl -n "$NAMESPACE" rollout status deployment/keycloak-operator --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/postgres --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s
echo "[playground] Operator, PostgreSQL and tester ready."

echo "[playground] Applying the Keycloak resource..."
kubectl apply -f "$MANIFEST_DIR/keycloak.yaml"
wait_for_keycloak_ready || { echo "[playground] ERROR: Keycloak did not become Ready." >&2; exit 1; }

echo "[playground] Importing the realm inventory..."
kubectl apply -f "$MANIFEST_DIR/realm-import-inventory.yaml"
for _ in $(seq 1 60); do
  done_status="$(kubectl -n keycloak get keycloakrealmimport inventory \
    -o jsonpath='{.status.conditions[?(@.type=="Done")].status}' 2>/dev/null || true)"
  [ "$done_status" = "True" ] && break
  sleep 5
done

echo "[playground] Ready."
kubectl -n keycloak get keycloak,statefulset,pods
