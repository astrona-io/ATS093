# Solution: Make Keycloak Observable

Work the task yourself first. Running `astrona submit -c sections/section-050/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: JSON logs, the log level, and health and metrics with the scrape interval.

## Step 1: Read the current options

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.additionalOptions}{"\n"}'
kubectl -n keycloak logs keycloak-0 --tail=3
```

Two options are set and the log is plain text.

## Step 2: Patch the resource

A merge patch replaces `additionalOptions` completely, so the patch repeats the two options that must stay:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{"serviceMonitor":{"interval":"15s"},"additionalOptions":[
  {"name":"health-enabled","value":"true"},
  {"name":"metrics-enabled","value":"true"},
  {"name":"log-console-output","value":"json"},
  {"name":"log-level","value":"INFO,org.keycloak.events:debug"}]}}'
```

## Step 3: Wait for the new pod

The operator rolls the pod because the options changed:

```sh
kubectl -n keycloak rollout status statefulset/keycloak --timeout=300s
kubectl -n keycloak logs keycloak-0 --tail=3
```

The lines are JSON now. If the old pod stays, check `kubectl -n keycloak get keycloak keycloak -o yaml` for a condition that explains it.

## Step 4: Submit

```sh
astrona submit -c sections/section-050/module-01/labs/lab-01
```
