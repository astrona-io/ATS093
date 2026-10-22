# Overview: Back Up, Restore And Upgrade Keycloak (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys Keycloak with two instances on PostgreSQL and creates two realms, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | Keycloak 26.8.1 with two instances on the database `keycloak`; update strategy at its default, `RecreateOnImageChange` |
  | `inventory` | The realm, with the user `alice` (password `alice-password`) and the public client `inventory-cli` |
  | `restore-check` | An empty realm that exists only to show whether a restore brought data back |
  | `postgres` | PostgreSQL 17 with the database `keycloak` on an `emptyDir`, and an empty folder `/backup` for dump files. Deleting this pod deletes all data |
  | `tester` | Client pod with `curl` and `jq` |

## Helpers

Paste these once in each new terminal. `run_sql` runs one SQL statement in a database (the second argument, default `keycloak`). `list_databases` lists the databases in PostgreSQL. `kcadm` and `kcadm_login` run the administration tool in `keycloak-0` with the initial admin Secret; sign in again after the pods restart. `show_conditions` prints the conditions of the `Keycloak` resource.

```sh
run_sql() {
  kubectl -n keycloak exec deploy/postgres -- psql -U keycloak -d "${2:-keycloak}" -c "$1"
}
list_databases() {
  kubectl -n keycloak exec deploy/postgres -- psql -U keycloak -d keycloak -lqt | cut -d'|' -f1 | sed '/^ *$/d'
}
kcadm() {
  kubectl -n keycloak exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm_login() {
  kcadm config credentials --server http://localhost:8080 --realm master \
    --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
    --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
}
show_conditions() {
  kubectl -n keycloak get keycloak keycloak \
    -o go-template='{{range .status.conditions}}{{.type}}={{.status}} {{.message}}{{"\n"}}{{end}}'
}
```

Use them like this: `run_sql 'select name from realm;'`, `run_sql 'select name from realm;' keycloak_restored`, `list_databases`, `kcadm_login` then `kcadm get realms --fields realm`, `show_conditions`.

## Practice tasks

- Take a dump, create a new user in `inventory`, restore the dump into a new database and switch Keycloak to it. Is the new user there? Copy it over from the old database with `kcadm.sh`, not with SQL.
- Switch back to the original database by changing `spec.db.database` again, and check which realms you see.
- Set `spec.image` to `quay.io/keycloak/keycloak:26.8.1` (the same image the operator already uses) and see whether the operator restarts anything.
- Change the update strategy to `Explicit`, set `spec.update.revision` to `1`, and compare what a configuration change does before and after you change the revision.
- Save the `Keycloak` and `KeycloakRealmImport` resources to files with only `metadata.name`, `metadata.namespace` and `spec`, the way you would keep them in Git.
