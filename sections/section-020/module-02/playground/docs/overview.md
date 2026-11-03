# Overview: Tune Caches And Sessions (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys a Keycloak with **two instances** and imports the realm `inventory`, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | Two instances (`keycloak-0`, `keycloak-1`) of Keycloak 26.8.1 on PostgreSQL, metrics and health on, no cache limits set |
  | `inventory` (`KeycloakRealmImport`) | The realm `inventory` with the user `alice` (password `alice-password`) and the public client `inventory-cli` |
  | `postgres` | PostgreSQL 17 with the database `keycloak` |
  | `tester` | Client pod with `curl` and `jq` |

Two Keycloak pods need about 3 GiB of memory, and the first start can take several minutes.

## Practice tasks

- Add `cache-embedded-users-max-count` with the value `2000` to `spec.additionalOptions` and watch the rolling update with `kubectl -n keycloak get pods -w`.
- Print the option inside a pod: `kubectl -n keycloak exec keycloak-0 -- printenv | grep CACHE`.
- Ask each pod for `vendor_cluster_size` on port `9000` from the `tester` pod and check that the value is `2` after the update.
- Sign `alice` in and open Sessions in the administration console of the realm `inventory` to see the session that Keycloak keeps in the database.
- Add `cache-embedded-mtls-rotation-interval-days` and read the container arguments to see how the operator passes it.
