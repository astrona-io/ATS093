# Overview: Export, Import And Migrate Realms (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys one Keycloak and imports the realm `inventory`, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance of Keycloak 26.8.1 on PostgreSQL |
  | `inventory` (`KeycloakRealmImport`) | The realm `inventory` with the users `alice` and `bob`, the realm role `auditor`, the group `ops`, the public client `inventory-cli` and the confidential client `inventory-api` |
  | `postgres` | PostgreSQL 17 with the database `keycloak` |
  | `tester` | Client pod with `curl` and `jq` |

## Helper

Paste this once in each new terminal. It prints an administrator access token for the master realm, read through the `tester` pod.

```sh
admin_token() {
  local u p
  u="$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)"
  p="$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
  kubectl -n keycloak exec deploy/tester -- curl -s http://keycloak-service:8080/realms/master/protocol/openid-connect/token \
    -d grant_type=password -d client_id=admin-cli -d username="$u" -d password="$p" | \
    kubectl -n keycloak exec -i deploy/tester -- jq -r .access_token
}
```

## Practice tasks

- Take a partial export: `curl -s -X POST -H "Authorization: Bearer $(admin_token)" "http://keycloak-service:8080/admin/realms/inventory/partial-export?exportClients=true&exportGroupsAndRoles=true"`, run from inside the `tester` pod with `kubectl -n keycloak exec deploy/tester -- sh -c '...'`.
- Look at the client `inventory-api` in the result. What does its `secret` field hold, and are `alice` and `bob` in the file?
- Run the same request with `exportClients=false` and compare the keys of the result with `jq 'keys'`.
- Read the import Job: `kubectl -n keycloak get job,pods` and the logs of its pod.
- Apply the same `KeycloakRealmImport` again and note what happens to a realm that already exists.
