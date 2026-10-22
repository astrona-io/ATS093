# Solution: Keep Sessions Alive Through A Pod Restart

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass. Note that the session check deletes `keycloak-0` each time it runs.

The grader checks five things: two ready instances, the memory request and limit, no `cache=local`, a cluster size of `2` on both pods, and a session that survives the deletion of `keycloak-0`.

## Step 1: Why is Keycloak down?

Start with the conditions and the pods:

```sh
kubectl -n keycloak get keycloak keycloak \
  -o go-template='{{range .status.conditions}}{{.type}}={{.status}} {{.message}}{{"\n"}}{{end}}'
kubectl -n keycloak get pods
```

`Ready` is `False`, and `keycloak-0` is `Pending`. A pending pod has not been placed on a node; its events say why:

```sh
kubectl -n keycloak describe pod keycloak-0 | tail -8
```

The scheduler reports that no node has enough memory. Read what the resource asks for:

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.resources}' | jq
```

The resource requests `16Gi` of memory per pod. No node in this cluster has that much, so the pod can never start. This is the fault that keeps Keycloak down.

## Step 2: Why could it not survive a pod loss?

Read the rest of the resource with the incident report in mind:

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.instances} {.spec.additionalOptions}{"\n"}'
```

Two more faults show up. `instances` is `1`, so losing that one pod means losing the service. And `additionalOptions` sets `cache` to `local`, so even with two pods, each would keep private caches and run as a separate server.

## Step 3: Fix all three in one change

Set two instances, remove the `cache` option, and give each pod a request that fits and a limit of at least `1Gi`:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{
  "instances":2,
  "additionalOptions":[{"name":"health-enabled","value":"true"},{"name":"metrics-enabled","value":"true"}],
  "resources":{"requests":{"memory":"768Mi","cpu":"250m"},"limits":{"memory":"1536Mi"}}}}'
```

Wait for both pods:

```sh
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

## Step 4: Prove the cluster

Read the cluster size on each pod:

```sh
for pod in keycloak-0 keycloak-1; do
  POD_IP=$(kubectl -n keycloak get pod "$pod" -o jsonpath='{.status.podIP}')
  echo "$pod: $(kubectl -n keycloak exec deploy/tester -- curl -s "http://$POD_IP:9000/metrics" | grep '^vendor_cluster_size')"
done
```

Both pods report `2`. If one still reports `1`, wait half a minute and read it again.

## Step 5: Prove the session survives

Do what the grader does. Sign `alice` in and keep the refresh token; the request uses the password grant, which OAuth 2.1 drops and which is used here only to test from a terminal. Then delete `keycloak-0`, wait, and refresh:

```sh
REFRESH_TOKEN=$(kubectl -n keycloak exec deploy/tester -- \
  curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password | jq -r .refresh_token)
kubectl -n keycloak delete pod keycloak-0
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak exec deploy/tester -- \
  curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=refresh_token -d client_id=inventory-cli \
    -d refresh_token="$REFRESH_TOKEN" | jq -r 'if .access_token then "new access token issued" else . end'
```

The answer says a new access token was issued. While `keycloak-0` was gone, `keycloak-1` served every request, and the session itself was safe in the database.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix only the memory request | Keycloak starts, as one pod with private caches. The service is up and still not highly available |
| Set `instances: 2` and keep `cache=local` | Two pods, each a cluster of one. The grader reads `vendor_cluster_size` on both |
| Remove `resources` altogether | The operator then requests 1700MiB per pod; two may not fit on the machine |
| Switch off the network policy "to let the pods talk" | It changes nothing for clustering, and the grader rejects it |

## Common mistakes

- Stopping after Keycloak is `Ready` again. Two of the three faults do not stop Keycloak from starting.
- Replacing `additionalOptions` without `metrics-enabled`. The cluster size can then not be read.
- Expecting the session to survive only because of the cluster. Here it is the database that keeps it; the cluster keeps the service answering while a pod is gone.
