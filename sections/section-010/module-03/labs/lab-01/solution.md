# Solution: Update A Realm That Was Already Imported

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the client `inventory-web`, the access token lifespan, and that `alice` and the import are untouched.

## Step 1: Sign the administration tool in

The operator keeps the administrator in the Secret `keycloak-initial-admin`. Define two helper functions and sign in:

```sh
kcadm() {
  kubectl -n keycloak exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm_login() {
  kcadm config credentials --server http://localhost:8080 --realm master \
    --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
    --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
}
kcadm_login
```

## Step 2: Show why a second import does nothing

A `KeycloakRealmImport` runs once. Check its status and the realm:

```sh
kubectl -n keycloak get keycloakrealmimport inventory -o jsonpath='{.status.conditions[?(@.type=="Done")].status}{"\n"}'
kcadm get realms/inventory --fields accessTokenLifespan
```

The condition `Done` is `True`. The import job created the realm and finished, so a changed import file is not applied again to a realm that exists. The change must go through the Admin REST API, and `kcadm.sh` is its command-line client.

## Step 3: Create the client and change the realm

```sh
kcadm create clients -r inventory -s clientId=inventory-web -s enabled=true -s publicClient=true \
  -s standardFlowEnabled=true -s 'redirectUris=["https://inventory.example.com/*"]'
kcadm update realms/inventory -s accessTokenLifespan=900
```

## Step 4: Check the result and submit

```sh
kcadm get clients -r inventory -q clientId=inventory-web --fields clientId,publicClient,redirectUris
kcadm get realms/inventory --fields accessTokenLifespan
```

The client is public and has the redirect URI, and the lifespan is `900`. Then submit:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```
