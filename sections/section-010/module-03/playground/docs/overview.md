# Overview: Manage Realms And Clients Declaratively (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys one Keycloak and imports one realm with a `KeycloakRealmImport`, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance of Keycloak 26.8.1 on PostgreSQL, HTTP on |
  | `inventory` (`KeycloakRealmImport`) | Created the realm `inventory` with the user `alice` (password `alice-password`) and the public client `inventory-cli`; the password comes from the Secret `inventory-secrets` through a placeholder |
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

- Print the import with `kubectl -n keycloak get keycloakrealmimport inventory -o yaml` and read its `Done` condition.
- Change the first name of `alice` in the `KeycloakRealmImport`, apply it, and check with `kcadm get users -r inventory -q username=alice` that the realm did not change.
- Create the client `probe-web` with `kcadm create clients -r inventory -s clientId=probe-web -s enabled=true`, then update its `redirectUris`.
- Run `kcadm get clients -r inventory --fields clientId` and find the clients the realm has by default.
- Run `kubectl explain keycloakoidcclient.spec` and list the fields of the client resource.
