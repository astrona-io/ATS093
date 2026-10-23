# Solution: Fix A Keycloak Resource That Never Becomes Ready

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the resource is `Ready` with one ready pod, the database settings use the `db` fields and the Secret `keycloak-db`, and the discovery document answers with the right issuer.

## Step 1: Read the conditions

Start where the operator reports back:

```sh
kubectl -n keycloak get keycloak keycloak \
  -o go-template='{{range .status.conditions}}{{.type}}={{.status}} {{.message}}{{"\n"}}{{end}}'
```

`Ready` is `False`. Its message says that not all instances are ready, which tells you that something is wrong but not what. The next place to look is the pod.

## Step 2: Follow the pod

List the pods and read the events of the Keycloak pod:

```sh
kubectl -n keycloak get pods
kubectl -n keycloak describe pod keycloak-0 | tail -15
```

The pod `keycloak-0` has the status `CreateContainerConfigError`, and the events say that the key `pass` was not found in the Secret `keycloak-db`. Kubernetes cannot even create the container, because the environment variable for the database password points at a key that does not exist. Check which keys the Secret really has:

```sh
kubectl -n keycloak get secret keycloak-db -o jsonpath='{.data}' | jq 'keys'
```

The keys are `password` and `username`. The resource asks for `pass`.

## Step 3: Fix the password key

Change only the key, in the resource:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge \
  -p '{"spec":{"db":{"passwordSecret":{"name":"keycloak-db","key":"password"}}}}'
```

The operator writes the change into the `keycloak` StatefulSet, but the StatefulSet does not replace a pod that never became ready. The old pod keeps the old configuration, so delete it. The StatefulSet then creates `keycloak-0` again from the fixed template:

```sh
kubectl -n keycloak delete pod keycloak-0
```

Wait a minute, then look at the pod again:

```sh
kubectl -n keycloak get pods
```

This time the container starts, and then it restarts again and again. The first fault hid the second one: Kubernetes now creates the container, so Keycloak itself runs and fails.

## Step 4: Read the Keycloak log

The Keycloak log says why the server stops:

```sh
kubectl -n keycloak logs keycloak-0 --tail=30
```

The log shows that Keycloak cannot open a connection to the database, and the address it tries uses the host `postgresql`. The Service is called `postgres`:

```sh
kubectl -n keycloak get service postgres
```

## Step 5: Fix the host and wait for Ready

Change the host in the resource:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge \
  -p '{"spec":{"db":{"host":"postgres"}}}'
```

The pod is still crashing with the old host, and for the same reason as before the StatefulSet does not replace it. Delete it again:

```sh
kubectl -n keycloak delete pod keycloak-0
```

Wait until the condition turns `True`. The first start against an empty database creates the schema and takes a minute or two:

```sh
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

## Step 6: Prove it from the tester pod

Ask Keycloak for the master realm's discovery document and pick out the issuer:

```sh
kubectl -n keycloak exec deploy/tester -- \
  curl -s http://keycloak-service:8080/realms/master/.well-known/openid-configuration | jq -r .issuer
```

The issuer is `http://keycloak-service:8080/realms/master`: the hostname from the resource, followed by the realm path.

## Step 7: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add `db-password` with the password as a value in `additionalOptions` | Keycloak may start, and the password now sits in plain text in the resource. The grader rejects any database option in `additionalOptions` |
| Rename the key in the Secret to `pass` | Other things that read `keycloak-db`, PostgreSQL among them, use `password`. The task forbids changing the Secret |
| Edit the StatefulSet's environment | The operator puts the StatefulSet back on its next reconciliation |
| Delete and recreate the resource | The faults come back with the same YAML, and the task forbids it |

## Common mistakes

- Stopping after the first fix. The password key hid the wrong host, and only a new pod showed the second fault.
- Reading only the conditions. `Ready=False` never names the cause; the pod events and the log do.
- Looking at an old pod's log. After each change the operator replaces the pod; read the log of the new one.
