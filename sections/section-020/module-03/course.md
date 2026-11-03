# Scale And Keep Keycloak Available

Two pods in one cluster protect you from one pod failing. They do not protect you from the people who run the cluster. A node drain that evicts both pods at once, two pods that share one node, a rolling update that starts the next pod before the last is ready: each of these takes Keycloak down although the cluster looked healthy a minute earlier.

This module is about availability you plan, as opposed to availability you hope for. Keep one sentence in mind: **a cluster survives failures you have counted, so write down how many pods may be missing at once and make Kubernetes enforce it.**

The module has four parts. **Planned And Unplanned Disruption** separates voluntary from involuntary loss and introduces the `PodDisruptionBudget`; a graded lab follows it. **Spreading The Pods** puts the pods on different nodes and zones. **Scaling Keycloak** changes the number of instances by hand and with an autoscaler, and names the limits. **Graceful Shutdown And Multi-Site** covers what a stopping pod does and the step beyond one cluster.

## Learning objectives

After this module you can:

- Tell a voluntary disruption from an involuntary one, and say which a `PodDisruptionBudget` controls.
- Write a budget with `minAvailable` or `maxUnavailable` and read its `ALLOWED DISRUPTIONS`.
- Spread Keycloak pods over nodes and zones with anti-affinity or topology spread constraints.
- Scale the `Keycloak` resource with `kubectl scale` and describe how a horizontal autoscaler uses the same interface.
- Name what grows with every extra instance: database connections, memory and cache traffic.
- Describe what happens to a request while a pod stops, and what a multi-site setup adds.

## Before you start

You need the modules Run Keycloak As A Cluster and Tune The Keycloak Pods With The Operator. You should know what a node drain does and what a readiness probe is.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with **two instances** on PostgreSQL |
| `inventory` | The realm, with the user `alice` (password `alice-password`) |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
