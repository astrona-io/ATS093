# Overview: Harden The Realm And The Server (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys one Keycloak and imports the realm `inventory`, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance of Keycloak 26.8.1 on PostgreSQL, HTTP on, metrics and health on |
  | `inventory` (`KeycloakRealmImport`) | The realm `inventory` with the users `alice` (password `alice-password`) and `bob` (password `bob-password`) and the public client `inventory-cli`; no password policy, no events |
  | `postgres` | PostgreSQL 17 with the database `keycloak` |
  | `tester` | Client pod with `curl` and `jq` |

## Helpers

Paste these once in each new terminal. `kcadm` runs the administration tool inside `keycloak-0`; `kcadm_login` signs it in with the initial admin Secret.

```sh
kcadm() {
  kubectl -n keycloak exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm_login() {
  kcadm config credentials --server http://localhost:8080 --realm master \
    --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
    --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
}
```

## Practice tasks

- Read the security settings of the realm with `kcadm get realms/inventory --fields passwordPolicy,eventsEnabled,adminEventsEnabled,revokeRefreshToken,accessTokenLifespan`.
- Set `passwordPolicy` to `length(12) and notUsername` and try `kcadm set-password -r inventory --username bob --new-password short`.
- Turn on login events and list them with `kcadm get events -r inventory`.
- Set `revokeRefreshToken` to `true` and use the same refresh token twice to see the second use refused.
- List the features of the server with `kubectl -n keycloak logs keycloak-0 | grep -i "profile\|feature"`.
