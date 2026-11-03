# Solution: Find Why Keycloak Does Not Start

Work the task yourself first. Running `astrona submit -c sections/section-050/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the Ready state, the database settings, and the health endpoint.

## Step 1: Start with the resource

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.message}{"\n"}{end}'
kubectl -n keycloak get pods
```

The resource is not Ready, and `keycloak-0` is not running normally.

## Step 2: Read the pod

```sh
kubectl -n keycloak describe pod keycloak-0 | tail -20
```

The event says the pod cannot start because a key is missing in the Secret `keycloak-db`. The Secret holds the keys `username` and `password`:

```sh
kubectl -n keycloak get secret keycloak-db -o jsonpath='{.data}' | jq 'keys'
```

## Step 3: Fix the key

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{"db":{"passwordSecret":{"name":"keycloak-db","key":"password"}}}}'
```

When the pod starts, it fails again. Read the log:

```sh
kubectl -n keycloak logs keycloak-0 --tail=20
```

The log says that the database `keycloak-prod` does not exist.

## Step 4: Fix the database name

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{"db":{"database":"keycloak"}}}'
kubectl -n keycloak get keycloak keycloak -w
```

A pod that never became Ready may keep running the old template. If it does not change after a minute, delete the pod and the StatefulSet starts a new one with the fixed template:

```sh
kubectl -n keycloak delete pod keycloak-0
```

## Step 5: Submit

```sh
astrona submit -c sections/section-050/module-02/labs/lab-01
```
