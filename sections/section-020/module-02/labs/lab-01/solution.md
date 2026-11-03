# Solution: Limit The Embedded Caches

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the options in the resource, the options inside both pods, and the cluster size.

## Step 1: Read the current options

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.additionalOptions}{"\n"}'
```

The resource has two options, `health-enabled` and `metrics-enabled`. A merge patch replaces a list as a whole, so the new list must contain these two as well.

## Step 2: Add the two limits

The option name for the cache `users` is `cache-embedded-users-max-count`, and for `sessions` it is `cache-embedded-sessions-max-count`. Patch the resource:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p \
  '{"spec":{"additionalOptions":[{"name":"health-enabled","value":"true"},{"name":"metrics-enabled","value":"true"},{"name":"cache-embedded-users-max-count","value":"2000"},{"name":"cache-embedded-sessions-max-count","value":"5000"}]}}'
```

These are build options for the cache subsystem, so the operator rolls the pods one after the other.

## Step 3: Wait for the update

```sh
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak get keycloak keycloak
```

Wait until both pods are Ready again. Pending pods after a change usually mean the node is short of memory; delete the pending pod and the StatefulSet creates it again.

## Step 4: Check the pods and the cluster

```sh
kubectl -n keycloak exec keycloak-0 -- printenv KC_CACHE_EMBEDDED_USERS_MAX_COUNT KC_CACHE_EMBEDDED_SESSIONS_MAX_COUNT
POD_IP="$(kubectl -n keycloak get pod keycloak-1 -o jsonpath='{.status.podIP}')"
kubectl -n keycloak exec deploy/tester -- curl -s "http://$POD_IP:9000/metrics" | grep '^vendor_cluster_size'
```

The first command prints `2000` and `5000`, and the metric is `2.0` on every pod. Then submit:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```
