# Tune Caches And Sessions

A cluster that works with the default cache settings can still fail in production. A realm with a million users fills the user cache until the pod is killed for running out of memory. A session store tuned for a laptop slows every token refresh under load. A security change breaks the traffic between the pods and the cluster quietly splits in two. The caches have defaults that fit a small server, and every default has a cost that grows with the data.

This module teaches you to size and secure the caches on purpose. Keep one sentence in mind: **a cache trades memory for fewer database round trips, so every limit is a choice about which one you can afford.**

The module has four parts. **Cache Types And Limits** names every cache, its default size and the option that bounds it. **Sessions In Memory And In The Database** covers persistent user sessions, offline sessions and the switches that change where sessions live. **Cluster Transport And Its Security** covers the cache stack, the encrypted transport between the pods and the topology options. **Sizing And Observing Caches** gives a method to choose numbers and to watch the result. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Name the local, distributed and replicated caches and the default size of each.
- Bound a cache with `cache-embedded-<name>-max-count` and name the caches that cannot be bounded.
- Explain persistent user sessions, offline sessions and what disabling session caching does.
- Choose a cache stack, and explain how the transport between the pods is encrypted by default.
- Describe what the topology options and the machine name do for the data owners.
- Choose limits from the data you have and check the effect with a metric and a log level.

## Before you start

You need the module Run Keycloak As A Cluster: the three kinds of cache, `jdbc-ping`, and the `vendor_cluster_size` metric. You also need to know how `additionalOptions` of the `Keycloak` resource work.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with **two instances** on PostgreSQL, with metrics and health switched on and no cache limits |
| `inventory` | The realm, with the user `alice` (password `alice-password`) and the public client `inventory-cli` |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl` and `jq` |

Two Keycloak pods need about 3 GiB of memory, and the first start can take up to ten minutes. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
