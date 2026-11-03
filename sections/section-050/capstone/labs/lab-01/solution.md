# Solution: Make Keycloak Observable End To End

Work the task yourself first. Running `astrona submit -c sections/section-050/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: metrics and health, the logging options, the events and a failed login, and the sign-in of `alice`.

## Step 1: Read what is set

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.additionalOptions}{"\n"}'
```

Health is on, there is no metrics option, and the root level is `debug`.

## Step 2: Patch the options

The patch replaces `additionalOptions`, so every option you want is listed:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{"additionalOptions":[
  {"name":"health-enabled","value":"true"},
  {"name":"metrics-enabled","value":"true"},
  {"name":"log-console-output","value":"json"},
  {"name":"log-level","value":"INFO,org.keycloak.events:debug"}]}}'
kubectl -n keycloak rollout status statefulset/keycloak --timeout=300s
```

## Step 3: Turn on the events

```sh
kcadm() { kubectl -n keycloak exec -i keycloak-0 -- /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config; }
kcadm config credentials --server http://localhost:8080 --realm master \
  --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
  --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
kcadm update realms/inventory -s eventsEnabled=true -s eventsExpiration=604800
```

## Step 4: Prove it

Fail a login and list the event:

```sh
kubectl -n keycloak exec deploy/tester -- curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=wrong
kcadm get events -r inventory -q type=LOGIN_ERROR -q max=5
kubectl -n keycloak exec deploy/tester -- curl -s http://$(kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.status.podIP}'):9000/metrics | head -5
```

## Step 5: Submit

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```
