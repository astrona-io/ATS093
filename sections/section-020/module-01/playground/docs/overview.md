# Overview: Run Keycloak As A Cluster (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys Keycloak with two instances on PostgreSQL and imports one realm, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | Keycloak 26.8.1 with **two instances**, `keycloak-0` and `keycloak-1`, behind `keycloak-service` on port `8080`; metrics on port `9000` of each pod |
  | `inventory` | The realm, with the user `alice` (password `alice-password`) and the public client `inventory-cli` |
  | `postgres` | PostgreSQL 17 with the database `keycloak`; credentials in the Secret `keycloak-db` |
  | `tester` | Client pod with `curl` and `jq` |

## Helpers

Paste these once in each new terminal. `cluster_sizes` prints the `vendor_cluster_size` metric of each Keycloak pod. `cluster_views` prints the latest `ISPN000094` log line of each pod. `run_sql` runs one SQL statement in the Keycloak database. `get_refresh_token` signs `alice` in with the password grant, which OAuth 2.1 drops and which is used here only to test from a terminal, and prints the refresh token.

```sh
cluster_sizes() {
  for pod in $(kubectl -n keycloak get pods -l app=keycloak -o name | sed 's|pod/||'); do
    POD_IP=$(kubectl -n keycloak get pod "$pod" -o jsonpath='{.status.podIP}')
    echo "$pod: $(kubectl -n keycloak exec deploy/tester -- curl -s "http://$POD_IP:9000/metrics" | grep '^vendor_cluster_size')"
  done
}
cluster_views() {
  for pod in $(kubectl -n keycloak get pods -l app=keycloak -o name | sed 's|pod/||'); do
    echo "$pod: $(kubectl -n keycloak logs "$pod" | grep ISPN000094 | tail -1)"
  done
}
run_sql() {
  kubectl -n keycloak exec deploy/postgres -- psql -U keycloak -d keycloak -c "$1"
}
get_refresh_token() {
  kubectl -n keycloak exec deploy/tester -- \
    curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password | jq -r .refresh_token
}
```

Use them like this: `cluster_sizes`, `cluster_views`, `run_sql 'select name from realm;'`, `REFRESH_TOKEN=$(get_refresh_token)`. If `cluster_sizes` prints nothing for a pod, check the label of the Keycloak pods with `kubectl -n keycloak get pods --show-labels` and change the `-l` selector to match.

## Practice tasks

- Delete `keycloak-1` and run `cluster_sizes` and `cluster_views` while it comes back. Note when the size drops to `1` and when it returns to `2`.
- Change `spec.instances` to `3` and see whether the third pod fits on your machine. Put it back to `2`.
- Look for the table `jdbc-ping` uses with `run_sql '\dt'` and read which rows it holds while two pods run.
- Get a refresh token, delete both pods, and use the refresh token once the resource is `Ready` again.
- Set `cache` to `local` in `additionalOptions`, compare `cluster_sizes` before and after, and remove the option again.
