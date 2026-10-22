#!/usr/bin/env bash
# Runs before the reference solution. Waits until the operator answers, so the
# solution's kubectl apply of Keycloak resources does not race the CRDs.
set -eu

kubectl -n keycloak rollout status deployment/keycloak-operator --timeout=600s
kubectl -n keycloak rollout status deployment/postgres --timeout=300s
