#!/usr/bin/env bash
# Installs the Keycloak Operator 26.8.1 into the namespace keycloak, then
# PostgreSQL and the tester pod.
#
# This prepares the environment ONLY. It never creates the objects the task
# asks for.
set -euo pipefail

OPERATOR_VERSION="26.8.1"
BASE="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${OPERATOR_VERSION}/kubernetes"
NAMESPACE="keycloak"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

echo "[setup] Applying the namespace, PostgreSQL and the tester pod..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"

echo "[setup] Installing the Keycloak Operator ${OPERATOR_VERSION}..."
kubectl apply -f "$BASE/keycloaks.k8s.keycloak.org-v1.yml"
kubectl apply -f "$BASE/keycloakrealmimports.k8s.keycloak.org-v1.yml"
kubectl -n "$NAMESPACE" apply -f "$BASE/kubernetes.yml"
kubectl wait --for=condition=Established crd/keycloaks.k8s.keycloak.org --timeout=60s
kubectl wait --for=condition=Established crd/keycloakrealmimports.k8s.keycloak.org --timeout=60s

kubectl -n "$NAMESPACE" rollout status deployment/keycloak-operator --timeout=600s
kubectl -n "$NAMESPACE" rollout status deployment/postgres --timeout=300s
kubectl -n "$NAMESPACE" rollout status deployment/tester --timeout=300s
echo "[setup] Operator, PostgreSQL and tester ready."
