# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Clustering

## Scenario

Last night someone "tuned" the `Keycloak` resource in the namespace `keycloak` before a load test. Since then Keycloak is down, and the incident report asks for more than a restart: the service must survive the loss of any single pod without signing users out.

The realm `inventory`, the user `alice` (password `alice-password`) and the client `inventory-cli` are in the database and must stay there.

## Your task

In the namespace `keycloak`:

1. Find every reason Keycloak is down now, and every reason it could not survive the loss of a pod even when it runs.
2. Fix the `Keycloak` resource so that two instances run as one cluster.
3. Prove that `alice`'s session outlives a deleted pod. The grader deletes `keycloak-0` and then uses a refresh token `alice` got before.

## Constraints

- **Two instances, one cluster.** Both pods must report a `vendor_cluster_size` of `2` on port `9000`.
- Each pod must request at most `1Gi` of memory, so that two pods fit on this machine, and be limited to at least `1Gi`.
- Keep `metrics-enabled` on, and do not switch off the operator's network policy.
- Change the `Keycloak` resource only. Do not touch the StatefulSet, the database or the realm.

## Done when

- The `Keycloak` resource is `Ready` with two instances and two ready pods.
- The memory request is at most `1Gi` and the limit at least `1Gi`.
- No `additionalOptions` entry sets `cache` to `local`.
- Both pods report `vendor_cluster_size` `2`.
- A refresh token issued before `keycloak-0` is deleted still works afterwards.
