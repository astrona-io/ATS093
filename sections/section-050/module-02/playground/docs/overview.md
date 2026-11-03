# Overview: Events, Tracing And Troubleshooting (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator and deploys one Keycloak, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance of Keycloak 26.8.1 on PostgreSQL, with health and metrics on |
  | `inventory` (`KeycloakRealmImport`) | The realm `inventory` with the users `alice` and `bob` and the public client `inventory-cli`; events are off |
  | `postgres` | PostgreSQL 17 with the database `keycloak` |
  | `tester` | Client pod with `curl` and `jq` |

## Helpers

Paste these once in each new terminal. `kcadm` runs the administration tool inside `keycloak-0`; `kcadm_login` signs it in with the initial admin Secret.

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
```

## Practice tasks

- Turn on login events: `kcadm update realms/inventory -s eventsEnabled=true`, then sign in as `alice` and as `bob` with a wrong password, and list them with `kcadm get events -r inventory`.
- Compare the events of type `LOGIN` and `LOGIN_ERROR`, and read the `details` of a failed one.
- Break the `Keycloak` resource on purpose, for example with a wrong `db.database`, and practise the order: resource conditions, pod, events, log.
- Add `tracing-enabled` with the value `true` to `additionalOptions` and look at the log for the exporter; there is no collector, so find the message about it.
- Read the previous log of a restarted container with `kubectl -n keycloak logs keycloak-0 --previous`.
