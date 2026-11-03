#!/usr/bin/env bash
# PASS when logs are JSON, root is info and the events category is debug.
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

POD_IP="$(kubectl -n "$NAMESPACE" get pod keycloak-0 -o jsonpath='{.status.podIP}' 2>/dev/null)"
[ -n "$POD_IP" ] || { echo "FAIL: keycloak-0 has no pod IP."; exit 1; }
T() { kubectl -n "$NAMESPACE" exec deploy/tester -- curl -s --max-time 10 "$@"; }
ENVV() { kubectl -n "$NAMESPACE" get pod keycloak-0 -o jsonpath="{.spec.containers[0].env[?(@.name==\"$1\")].value}" 2>/dev/null; }
[ "$(ENVV KC_LOG_CONSOLE_OUTPUT)" = "json" ] || { echo "FAIL: log-console-output is '$(ENVV KC_LOG_CONSOLE_OUTPUT)', not json."; exit 1; }
L="$(ENVV KC_LOG_LEVEL)"
case "$L" in
  info,*|INFO,*|info|INFO) ;;
  *) echo "FAIL: the root level in '${L:-not set}' is not info."; exit 1 ;;
esac
case "$L" in *"org.keycloak.events:debug"*) ;; *) echo "FAIL: org.keycloak.events is not at debug in '$L'."; exit 1 ;; esac
LINES="$(kubectl -n "$NAMESPACE" logs keycloak-0 --tail=5 2>/dev/null)"
printf '%s\n' "$LINES" | kubectl -n "$NAMESPACE" exec -i deploy/tester -- jq -e . >/dev/null 2>&1 || { echo "FAIL: the latest log lines are not JSON."; exit 1; }
echo "PASS: logs are JSON, root is info and the events category is debug."
exit 0
