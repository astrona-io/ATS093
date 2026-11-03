# Overview: Scale And Keep Keycloak Available (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys a Keycloak with **two instances** and imports the realm `inventory`, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | Two instances (`keycloak-0`, `keycloak-1`) of Keycloak 26.8.1 on PostgreSQL, metrics and health on |
  | `inventory` (`KeycloakRealmImport`) | The realm `inventory` with the user `alice` (password `alice-password`) |
  | `postgres` | PostgreSQL 17 with the database `keycloak` |
  | `tester` | Client pod with `curl` and `jq` |

Two Keycloak pods need about 3 GiB of memory, and the first start can take several minutes. There is only one node, so you cannot see pods spread over nodes; you can still read and test the objects.

## Practice tasks

- Print the selector of the StatefulSet with `kubectl -n keycloak get statefulset keycloak -o jsonpath='{.spec.selector.matchLabels}'` and use it in a `PodDisruptionBudget` of your own.
- Create a budget with `maxUnavailable: 1` and read `kubectl -n keycloak get pdb` to see `ALLOWED DISRUPTIONS`.
- Change the budget to `minAvailable: 2` and watch `ALLOWED DISRUPTIONS` fall to `0`.
- Run `kubectl -n keycloak get statefulset keycloak -o yaml` and find `terminationGracePeriodSeconds` and the readiness probe.
- Scale the resource with `kubectl -n keycloak scale keycloak keycloak --replicas=3` and watch the third pod start, then scale back to `2`.
