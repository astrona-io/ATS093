# Solution: Deploy Keycloak And Its Realm With The Operator

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the `Keycloak` resource is ready; its database, hostname, ingress and resources settings; the realm import finished; no literal password in the import; and a token for `alice` with the right issuer.

## Step 1: Look at what is there

Check that the operator runs and read the keys of the two Secrets, without printing their values:

```sh
kubectl -n keycloak get deployment keycloak-operator postgres
kubectl -n keycloak get secret keycloak-db -o jsonpath='{.data}' | jq 'keys'
kubectl -n keycloak get secret inventory-secrets -o jsonpath='{.data}' | jq 'keys'
```

The keys are `password` and `username` in `keycloak-db`, and `alice-password` in `inventory-secrets`. Those names go into the resources.

## Step 2: Write the Keycloak resource

Save this as `keycloak-keycloak.yaml`:

```yaml
apiVersion: k8s.keycloak.org/v2beta1
kind: Keycloak
metadata:
  name: keycloak
  namespace: keycloak
spec:
  instances: 1
  db:
    vendor: postgres
    host: postgres
    database: keycloak
    usernameSecret:
      name: keycloak-db
      key: username
    passwordSecret:
      name: keycloak-db
      key: password
  http:
    httpEnabled: true
  hostname:
    hostname: http://keycloak-service:8080
  ingress:
    enabled: false
  additionalOptions:
    - name: health-enabled
      value: "true"
    - name: metrics-enabled
      value: "true"
  resources:
    requests:
      memory: 768Mi
      cpu: 250m
    limits:
      memory: 1536Mi
```

Apply it:

```sh
kubectl apply -f keycloak-keycloak.yaml
```

Then wait until it is ready. The first start creates the database schema and takes a few minutes:

```sh
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

If the wait times out, read the conditions, the pod events and the Keycloak log, in that order.

## Step 3: Write the realm import

The password must not appear in the resource, so the realm uses the placeholder `${ALICE_PASSWORD}`, and `spec.placeholders` says where its value comes from.

Save this as `keycloakrealmimport-inventory.yaml`:

```yaml
apiVersion: k8s.keycloak.org/v2beta1
kind: KeycloakRealmImport
metadata:
  name: inventory
  namespace: keycloak
spec:
  keycloakCRName: keycloak
  placeholders:
    ALICE_PASSWORD:
      secret:
        name: inventory-secrets
        key: alice-password
  realm:
    realm: inventory
    enabled: true
    users:
      - username: alice
        enabled: true
        email: alice@example.com
        emailVerified: true
        firstName: Alice
        lastName: Example
        credentials:
          - type: password
            value: ${ALICE_PASSWORD}
            temporary: false
    clients:
      - clientId: inventory-cli
        enabled: true
        publicClient: true
        standardFlowEnabled: false
        directAccessGrantsEnabled: true
```

Apply it:

```sh
kubectl apply -f keycloakrealmimport-inventory.yaml
```

Then check the result. The operator runs a Job for the import; wait until `Done` is `True`:

```sh
kubectl -n keycloak get jobs
kubectl -n keycloak get keycloakrealmimport inventory \
  -o go-template='{{range .status.conditions}}{{.type}}={{.status}} {{.message}}{{"\n"}}{{end}}'
```

## Step 4: Prove it with a token

Request a token for `alice` from the `tester` pod and read two claims of its payload. This uses the password grant, which OAuth 2.1 drops; it is here only to test from a terminal:

```sh
kubectl -n keycloak exec deploy/tester -- \
  curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password -d scope=openid \
  | jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - (length % 4)) % 4)) | @base64d | fromjson | "\(.iss) \(.preferred_username)"'
```

The command prints `http://keycloak-service:8080/realms/inventory alice`. The password `alice-password` reached Keycloak from the Secret, through the placeholder.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Write `alice-password` straight into `credentials.value` | It works, and the password now lives in the resource and in every copy of it. The grader rejects it |
| Create the realm with `kcadm.sh` | The realm exists, but nothing on a new cluster would create it again. The task asks for the import |
| Leave out `resources` | The operator asks for 1700MiB of memory per pod; on a small machine the pod can stay `Pending` |
| Apply the realm import first | It names a `Keycloak` resource that does not exist yet and cannot run |

## Common mistakes

- Indenting `credentials` or `clients` one level wrong. `kubectl apply` may accept it, and the import then creates a realm without the user or the client.
- Forgetting `emailVerified`, `firstName` or `lastName`. The default user profile wants them, and the token request then fails with an account that is not fully set up.
- Changing the import after it ran and expecting the realm to change. An import only creates.
