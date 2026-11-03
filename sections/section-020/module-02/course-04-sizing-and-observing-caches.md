# Sizing And Observing Caches

A limit that you cannot justify is a guess. This part gives a method to choose numbers, and the two tools to watch the result: the debug log of the cache configuration and the metrics endpoint.

## Choose limits from the data

Work in this order:

1. Count what you have: users, clients per realm, groups, peak concurrent sessions and offline sessions.
2. Decide what must stay hot. A cache that holds your whole user table wastes memory if most users sign in once a month. A cache that is smaller than the daily active users causes a database read for almost every request.
3. Start from the default, then move one cache at a time and measure.
4. Leave headroom in the pod. The Java heap must hold the caches and the work of the requests. The memory limit of the container must be larger than the heap.

A rough rule: size `users` for the active users of a day, `realms` for the clients and roles of the realms that are in use, and `sessions` for the peak concurrent sessions divided by the number of pods, plus a margin for the case that a pod fails and the others take over its sessions.

## What happens at the edge

When a cache is too small the symptoms are not errors. Response times rise, and the database sees more reads. When it is too large the symptoms are errors: garbage collection pauses, then `OutOfMemoryError`, then a pod killed by Kubernetes. Prefer a limit that is a little too small. The cost of an extra query is lower than the cost of a crashed pod.

## Show the applied configuration

Keycloak logs the Infinispan configuration it applied when you raise the log level of one category. Add the option below in `additionalOptions`:

```text
log-level=info,org.keycloak.connections.infinispan.DefaultInfinispanConnectionProviderFactory:debug
```

After the pod restarts, search its log for the configuration of each cache and read the maximum entries. Use this to confirm that a limit reached the cache, and take the level out again afterwards because it adds log lines.

## Read the metrics

Metrics are on in this playground, so each pod serves them on port `9000`. The cluster size has been your proof of membership already. List the Infinispan and cache related metrics that your version exposes before you choose which to watch:

```sh
POD_IP="$(kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.status.podIP}')"
kubectl -n keycloak exec deploy/tester -- curl -s "http://$POD_IP:9000/metrics" | grep -E '^(vendor_|jvm_memory)' | cut -d'{' -f1 | sort -u | head -40
```

Track three things over time: the JVM heap in use against the heap maximum, the cluster size, and the database pool use. Together they tell whether a cache change moved the load from memory to the database or the other way.

## A safe way to change limits

Cache limits are build time options for the cluster, so a change rolls all pods. Plan it as you plan any rollout:

- Change one option at a time in a test cluster that has realistic data.
- Apply the change with the `Keycloak` resource from version control, not with a manual edit.
- Watch the rollout with `kubectl rollout status` and check `vendor_cluster_size` on every pod afterwards.
- Keep the previous resource so you can go back.

## Common mistakes

- Setting a limit on `work`, `actionTokens` or `authenticationSessions`: the option does not exist for them.
- Replacing the `additionalOptions` list with a merge patch and losing `metrics-enabled`.
- Disabling session caching and then wondering why the database connection pool is full.
- Overriding the cache XML for a problem a `cache-` option already solves.
