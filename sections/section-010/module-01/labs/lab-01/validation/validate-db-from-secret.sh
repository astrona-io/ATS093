#!/usr/bin/env bash
# PASS when the database host is postgres and both credentials are read from the
# Secret keycloak-db through the db fields, with no database option typed into
# additionalOptions.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

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

DB="$(kubectl -n "$NAMESPACE" get keycloak keycloak -o jsonpath='{.spec.db.host} {.spec.db.usernameSecret.name}/{.spec.db.usernameSecret.key} {.spec.db.passwordSecret.name}/{.spec.db.passwordSecret.key}')"
if [ "$DB" != "postgres keycloak-db/username keycloak-db/password" ]; then
  echo "FAIL: expected host postgres and credentials from keycloak-db (username, password); found: $DB"
  exit 1
fi
OPTIONS="$(kubectl -n "$NAMESPACE" get keycloak keycloak -o jsonpath='{range .spec.additionalOptions[*]}{.name}{"\n"}{end}')"
if printf '%s\n' "$OPTIONS" | grep -qE '^db'; then
  echo "FAIL: a database option is set in additionalOptions. Use the db fields and the Secret instead."
  exit 1
fi
echo "PASS: the database settings come from the db fields and the Secret keycloak-db."
exit 0
