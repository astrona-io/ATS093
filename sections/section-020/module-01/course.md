# Run Keycloak As A Cluster

Setting `instances: 2` in a `Keycloak` resource starts a second pod in a minute. Whether those two pods form one cluster is a different question, and nothing in `kubectl get pods` answers it. Two pods that run side by side, each with its own private caches, look exactly like a healthy cluster until a user's request lands on the wrong one.

This module is about telling the two cases apart. Keep one sentence in mind: **the database holds what must survive, and Infinispan shares what must be fast.** Once you know which data lives where, you know what breaks when the pods do not talk to each other, and how to prove that they do.

The module has two parts. **The Database Is The Source Of Truth** looks at what Keycloak writes to PostgreSQL, including user sessions, and proves that a session outlives its pod. **Infinispan Caches And Cluster Discovery** explains the caches, how the pods find each other through the database, and the two signals that prove a cluster: a log line and a metric. A graded lab follows it.

## Learning objectives

After this module you can:

- Name what Keycloak stores in the database and what it keeps only in memory.
- Set the database fields and the connection pool of a `Keycloak` resource.
- Prove that a user session survives the restart of the pod that created it.
- Explain local, distributed and replicated caches, and name the Keycloak caches of each kind.
- Explain how `jdbc-ping` lets instances find each other, and which ports they use.
- Prove that two instances form one cluster with the `ISPN000094` log line and the `vendor_cluster_size` metric.

## Before you start

You need Kubernetes basics (StatefulSets, pod IP addresses, `kubectl exec`, `kubectl logs`) and you need to know what a `Keycloak` resource is: the custom resource from which the Keycloak Operator creates the StatefulSet `keycloak` and the Service `keycloak-service`. You also need to know what an access token and a refresh token are.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with **two instances**, `keycloak-0` and `keycloak-1`, on PostgreSQL, with metrics switched on |
| `inventory` | The realm, with the user `alice` (password `alice-password`) and the public client `inventory-cli` |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

Two Keycloak pods need about 3 GiB of memory, and the first start can take up to ten minutes. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
