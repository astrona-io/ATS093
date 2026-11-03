# Overview: Tune The Keycloak Pods With The Operator (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys one Keycloak through a `Keycloak` resource and imports one realm, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**. The operator is a controller that turns `Keycloak` and `KeycloakRealmImport` resources into the objects Keycloak needs, and it watches only this namespace.
- Everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance of Keycloak 26.8.1 on PostgreSQL with JSON console log, a topology spread constraint, `priorityClassName: system-cluster-critical` and explicit resource requests and limits |
  | `keycloak-0`, `keycloak-service` | The pod and the Service the operator created for it |
  | `keycloak-initial-admin` | The Secret with the temporary administrator's user name and password |
  | `inventory` (`KeycloakRealmImport`) | Created the realm `inventory` with the user `alice` (password `alice-password`) and the public client `inventory-cli` |
  | `postgres` | PostgreSQL 17 with the database `keycloak`; credentials in the Secret `keycloak-db` |
  | `tester` | Client pod with `curl` and `jq` |

## Helpers

Paste these once in each new terminal. `show_conditions` prints the status conditions of the `Keycloak` resource. `kcadm` runs the administration tool inside `keycloak-0`; `kcadm_login` signs it in with the initial admin Secret. `get_alice_token` asks for a token for `alice` with the password grant, which OAuth 2.1 drops and which is used here only to test from a terminal.

```sh
show_conditions() {
  kubectl -n keycloak get keycloak keycloak \
    -o go-template='{{range .status.conditions}}{{.type}}={{.status}} {{.message}}{{"\n"}}{{end}}'
}
kcadm() {
  kubectl -n keycloak exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm_login() {
  kcadm config credentials --server http://localhost:8080 --realm master \
    --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
    --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
}
get_alice_token() {
  kubectl -n keycloak exec deploy/tester -- \
    curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli \
      -d username=alice -d password=alice-password -d scope=openid
}
```

Use them like this: `show_conditions`, `kcadm_login` then `kcadm get realms --fields realm`, `get_alice_token | jq -r .access_token`.

## Practice tasks

- Print the pod template the operator built with `kubectl -n keycloak get statefulset keycloak -o yaml` and find where `resources`, `topologySpreadConstraints` and `priorityClassName` from the `Keycloak` resource ended up.
- Raise `spec.resources.requests.memory` to `64Gi`, watch `keycloak-0` stay `Pending`, read the reason with `kubectl -n keycloak describe pod keycloak-0`, and put the value back.
- Change `log-console-output` to `default`, wait for the new pod, and compare the first log lines with the JSON lines.
- Add an `additionalOptions` entry whose value comes from a Secret (`secret.name` and `secret.key` instead of `value`) and check the environment variable the operator adds to the pod.
- Add `unsupported.podTemplate` with `spec.terminationGracePeriodSeconds: 90` and find the field in the StatefulSet pod template.
