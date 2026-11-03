# Solution: Harden The Realm

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the password policy and its effect, the events, and the refresh token setting with the sign-in of `alice`.

## Step 1: Sign the administration tool in

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

## Step 2: Read the current settings

```sh
kcadm get realms/inventory --fields passwordPolicy,eventsEnabled,adminEventsEnabled,adminEventsDetailsEnabled,revokeRefreshToken
```

The policy is empty, the events are `false`, and `revokeRefreshToken` is `false`.

## Step 3: Change them in one call

The policy is a single string; rules are joined with `and`. The `update` verb changes only the fields you name:

```sh
kcadm update realms/inventory \
  -s 'passwordPolicy=length(12) and notUsername' \
  -s eventsEnabled=true -s adminEventsEnabled=true -s adminEventsDetailsEnabled=true \
  -s revokeRefreshToken=true
```

## Step 4: Check the effect and submit

A short password must now be refused, and the events show your own change:

```sh
kcadm set-password -r inventory --username bob --new-password 'Short1'
kcadm get admin-events -r inventory -q max=3 | head -20
```

The first command fails with a policy message. Then submit:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```
