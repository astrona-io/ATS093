# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Clustering

## Scenario

The identity team scaled Keycloak to two instances for high availability. Both pods in the namespace `keycloak` are `Running` and ready, and the `Keycloak` resource reports `Ready`. Yet the support desk sees odd behaviour: a client changed in the console keeps its old settings on some requests, and a user locked out after too many wrong passwords can sometimes keep trying.

The team suspects the two pods are not one cluster.

## Your task

In the namespace `keycloak`:

1. Prove whether `keycloak-0` and `keycloak-1` form one Infinispan cluster. Use the `vendor_cluster_size` metric on port `9000` of each pod.
2. Find the setting that keeps them apart, and fix the `Keycloak` resource so they form one cluster.
3. Prove the fix: both pods report a cluster of two members, and an access token that `keycloak-0` issues is accepted by the `userinfo` endpoint of `keycloak-1`.

## Constraints

- **Keep exactly two instances.** Dropping to one instance hides the problem; it does not fix it.
- Keep `metrics-enabled` on, so the cluster size can be read.
- Do not switch off the operator's network policy (`spec.networkPolicy.enabled`). The Keycloak pods can already reach each other through it.
- Change the `Keycloak` resource, not the StatefulSet.

## Done when

- The `Keycloak` resource is `Ready` with two instances and two ready pods.
- No `additionalOptions` entry sets `cache` to `local`, and the network policy is on.
- `vendor_cluster_size` is `2` on `keycloak-0` and on `keycloak-1`.
- A token from `keycloak-0` works on the `userinfo` endpoint of `keycloak-1`.
