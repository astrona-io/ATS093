# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** PodDisruptionBudget for a Keycloak cluster

## Scenario

Keycloak runs with two instances in the namespace `keycloak`. The platform team created a `PodDisruptionBudget` named `keycloak`. During the last maintenance window, a node drain hung for an hour because it could not evict a Keycloak pod.

## Your task

Fix the `PodDisruptionBudget` named `keycloak` so that:

1. It still covers both Keycloak pods.
2. One pod can be evicted at a time, and never both at once.

## Constraints

- Do not delete the `Keycloak` resource, and do not change the number of instances.
- Keep the name `keycloak` for the budget.
- Do not use more than one of `minAvailable` and `maxUnavailable`; a budget accepts only one of them.

## Done when

- The budget reports two expected pods and one allowed disruption.
- The budget keeps at least one pod through `minAvailable: 1` or `maxUnavailable: 1`.
- The `Keycloak` resource is Ready with two instances, and `alice` gets a token.
