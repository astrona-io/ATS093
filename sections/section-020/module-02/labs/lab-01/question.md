# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Limiting the Infinispan caches of a Keycloak cluster

## Scenario

Keycloak runs with two instances in the namespace `keycloak`, in one cluster. The realm `inventory` will grow to hundreds of thousands of users, and the pods have a memory limit of 1536 MiB. The capacity team wants the user cache and the user session cache bounded before the import starts, so the pods do not run out of memory.

## Your task

Change the `Keycloak` resource named `keycloak` so that:

1. The embedded cache `users` holds at most `2000` entries per node.
2. The embedded cache `sessions` holds at most `5000` entries per node.
3. Both instances run with the limits, and they still form one cluster.

## Constraints

- Use the documented cache options of the `Keycloak` resource (`spec.additionalOptions`). Do not supply your own cache configuration file.
- Keep `instances` at `2`, and keep the options `health-enabled` and `metrics-enabled` set to `true`.
- A merge patch replaces the whole `additionalOptions` list, so list every option you want to keep.

## Done when

- `cache-embedded-users-max-count` is `2000` and `cache-embedded-sessions-max-count` is `5000` in the `Keycloak` resource.
- Both pods have been restarted with the limits.
- The `Keycloak` resource is Ready, and each pod reports `vendor_cluster_size` `2`.
