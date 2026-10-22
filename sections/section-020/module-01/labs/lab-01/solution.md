# Solution: Join Two Keycloak Instances Into One Cluster

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: two ready instances, no `cache=local` and the network policy on, a cluster size of `2` on both pods, and a token that crosses from one pod to the other.

## Step 1: Measure the cluster

Ready pods do not prove a cluster, so ask each pod how many members it sees. The metric is on the management port `9000` of each pod; the `tester` pod sends the requests:

```sh
for pod in keycloak-0 keycloak-1; do
  POD_IP=$(kubectl -n keycloak get pod "$pod" -o jsonpath='{.status.podIP}')
  echo "$pod: $(kubectl -n keycloak exec deploy/tester -- curl -s "http://$POD_IP:9000/metrics" | grep '^vendor_cluster_size')"
done
```

Each pod reports `1`. Two pods run, and each one is a cluster of its own. The latest `ISPN000094` log line of each pod says the same, if it is still in the log:

```sh
kubectl -n keycloak logs keycloak-0 | grep ISPN000094 | tail -1
```

## Step 2: Find the setting

Two things can keep pods apart: the cache mode, and the network between them. Read the server options in the resource first:

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.additionalOptions}' | jq
```

The list has `cache` set to `local`. With `cache=local`, each Keycloak keeps private caches and never joins a cluster, even in production mode. The network policy is not the cause: the resource does not switch it off, and the operator's default policy lets the Keycloak pods reach each other on the clustering ports.

## Step 3: Remove the option

Patch the list without the `cache` entry. A merge patch replaces the whole list, so it keeps the other two options:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p \
  '{"spec":{"additionalOptions":[{"name":"health-enabled","value":"true"},{"name":"metrics-enabled","value":"true"}]}}'
```

The operator replaces the pods. Wait until the StatefulSet has rolled out and the resource is ready again:

```sh
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

## Step 4: Measure again

Run the loop from step 1 again. Both pods now report `2`. If one still reports `1`, wait half a minute: the second pod joins once it has registered in the database and the first pod has read its address.

## Step 5: Send a token across

Get a token for `alice` from `keycloak-0` directly, and send it to the `userinfo` endpoint of `keycloak-1`. The token request uses the password grant, which OAuth 2.1 drops; it is used here only to test from a terminal:

```sh
POD0_IP=$(kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.status.podIP}')
POD1_IP=$(kubectl -n keycloak get pod keycloak-1 -o jsonpath='{.status.podIP}')
ACCESS_TOKEN=$(kubectl -n keycloak exec deploy/tester -- \
  curl -s "http://$POD0_IP:8080/realms/inventory/protocol/openid-connect/token" \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid | jq -r .access_token)
kubectl -n keycloak exec deploy/tester -- \
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "http://$POD1_IP:8080/realms/inventory/protocol/openid-connect/userinfo" | jq -r .preferred_username
```

The answer is `alice`. Keep in mind that this check would pass even without a cluster, because the session and the signing keys come from the database. The cluster size is the real proof; the token is the user's view of it.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Scale to one instance | The cluster size is `1` and correct, and the deployment has a single point of failure again. The task requires two |
| Switch off the network policy | Nothing changes for clustering, and ports `7800` and `57800` open to every pod. The grader rejects it |
| Set `cache` to `ispn` explicitly | It works; it is the production default. Removing the entry is enough |
| Edit the StatefulSet's arguments | The operator puts them back on its next reconciliation |

## Common mistakes

- Reading the metric through `keycloak-service`. The Service sends each request to either pod; read each pod by its IP address.
- Dropping `metrics-enabled` when replacing the list. The pods then serve no metrics, and the cluster size cannot be read.
- Measuring right after the rollout. Give the second pod half a minute to join.
