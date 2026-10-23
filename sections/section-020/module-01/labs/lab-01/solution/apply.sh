#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# Taken from solution.md - if one changes, change the other.
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
replace_stuck_pods() {
  # A StatefulSet does not replace a pod that never became Ready, even after
  # the operator updated the pod template (seen on a live run). Delete pods
  # that are not Ready and still run an old revision, so the fixed template
  # is used. Healthy pods and pods on the new revision are left alone.
  local update_revision pod
  update_revision="$(kubectl -n "$NAMESPACE" get statefulset keycloak -o jsonpath='{.status.updateRevision}' 2>/dev/null)"
  [ -n "$update_revision" ] || return 0
  # StatefulSet pods are named keycloak-0, keycloak-1, ...
  for pod in $(kubectl -n "$NAMESPACE" get pods \
      -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.labels.controller-revision-hash}{" "}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null \
      | awk -v rev="$update_revision" '$1 ~ /^keycloak-[0-9]+$/ && $2 != rev && $3 != "true" {print $1}'); do
    kubectl -n "$NAMESPACE" delete pod "$pod" --wait=false
  done
}

wait_for_keycloak_ready() {
  for i in $(seq 1 120); do
    [ "$(keycloak_condition Ready)" = "True" ] && return 0
    [ $((i % 6)) -eq 0 ] && replace_stuck_pods
    sleep 5
  done
  return 1
}

# wait_for_reconciled: waits until the operator has acted on the latest change
# to the Keycloak resource: the Ready condition belongs to the current
# generation and is True, and no rolling update is running. A fixed sleep is
# not enough; on a busy node the operator starts the update later.
wait_for_reconciled() {
  local state
  for _ in $(seq 1 180); do
    state="$(kubectl -n "$NAMESPACE" get keycloak keycloak -o jsonpath='{.metadata.generation} {.status.conditions[?(@.type=="Ready")].observedGeneration} {.status.conditions[?(@.type=="Ready")].status} {.status.conditions[?(@.type=="RollingUpdate")].status}')"
    set -- $state
    [ "${1:-}" = "${2:-}" ] && [ "${3:-}" = True ] && [ "${4:-}" != True ] && return 0
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
kubectl -n "$NAMESPACE" patch keycloak keycloak --type merge -p \
  '{"spec":{"additionalOptions":[{"name":"health-enabled","value":"true"},{"name":"metrics-enabled","value":"true"}]}}'
# The operator replaces the pods one after the other; wait for the new ones.
wait_for_reconciled
wait_for_keycloak_ready
kubectl -n "$NAMESPACE" rollout status statefulset/keycloak --timeout=600s
sleep 30
