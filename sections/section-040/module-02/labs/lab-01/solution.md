# Solution: Export A Realm For Reuse

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the content of the file, the secret placeholder, and that the original realm is untouched.

## Step 1: Get an administrator token

Open a shell in the `tester` pod and sign in to the master realm with the initial admin credentials:

```sh
kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d; echo
kubectl -n keycloak exec -it deploy/tester -- sh
```

Inside the pod, use the two values:

```sh
T=$(curl -s http://keycloak-service:8080/realms/master/protocol/openid-connect/token \
  -d grant_type=password -d client_id=admin-cli -d username=<user> -d password=<password> | jq -r .access_token)
```

## Step 2: Take the partial export

```sh
curl -s -X POST -H "Authorization: Bearer $T" \
  'http://keycloak-service:8080/admin/realms/inventory/partial-export?exportClients=true&exportGroupsAndRoles=true' \
  > /tmp/inventory-export.json
jq '.clients[] | {clientId, secret}' /tmp/inventory-export.json
```

The secret of `inventory-api` is shown as ten asterisks, and `.users` is not in the file at all.

## Step 3: Replace the mask with a placeholder

```sh
jq '(.clients[] | select(.clientId=="inventory-api") | .secret) = "${API_SECRET}"' \
  /tmp/inventory-export.json > /tmp/out.json && mv /tmp/out.json /tmp/inventory-export.json
```

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```
