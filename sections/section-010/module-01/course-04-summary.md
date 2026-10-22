# Summary

The Keycloak Operator turns one short custom resource into a running Keycloak, and it keeps the cluster matching that resource. Working with it means changing the resource, never the objects the operator made from it.

## What you learned

The operator is a controller installed from the Keycloak project's manifests, with CRDs for `Keycloak` and `KeycloakRealmImport` in the API version `k8s.keycloak.org/v2beta1`. By default it watches only the namespace it is installed in, and it ignores resources anywhere else without an error. For each `Keycloak` resource it creates a StatefulSet named after the resource, the Service `<name>-service`, a headless Service for discovery, the Secret `<name>-initial-admin`, a network policy and, unless switched off, an Ingress. An edit to any of these lasts only until the next reconciliation.

A `Keycloak` resource needs a small set of fields: `instances`, `db` with the credentials in `usernameSecret` and `passwordSecret`, `http.httpEnabled` or a TLS Secret, `hostname`, `ingress.enabled` and `resources`. Other server options go into `additionalOptions` by their `kc.sh` name, and `kubectl explain keycloak.spec` prints the schema of every field. The operator reports through the `Ready`, `HasErrors` and `RecreateUpdateUsed` conditions. A `False` condition says that something is wrong; the pod events and the Keycloak log say what.

The operator creates a temporary administrator and stores its user name and password in the initial admin Secret. Read both from the Secret, and replace that administrator on a real system.

A `KeycloakRealmImport` creates a realm through a one-time Job, and `spec.placeholders` keeps passwords in a Secret. An import only ever creates: it never updates, overwrites or deletes a realm that already exists. The key facts to remember are these:

- Every change goes into the `Keycloak` resource; the operator rolls it out.
- `Ready=False` sends you to the pod events and the Keycloak log.
- Database credentials come from Secrets, never from `additionalOptions` values.
- A realm import creates a realm once and then has no further effect on it.

<!-- astrona:playground:destroy -->
