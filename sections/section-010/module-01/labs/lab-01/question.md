# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** The Keycloak Operator

## Scenario

A colleague applied a `Keycloak` resource named `keycloak` in the namespace `keycloak` before going on holiday. The API server accepted it, and the operator created a StatefulSet for it. Keycloak has never become ready.

The Secret `keycloak-db` holds the database user name (key `username`) and password (key `password`). PostgreSQL runs as the Service `postgres` in the same namespace, with the database `keycloak`.

## Your task

In the namespace `keycloak`:

1. Find out why the `Keycloak` resource is not ready. There is more than one reason.
2. Fix the `Keycloak` resource so that Keycloak starts and becomes ready.
3. Prove it: the master realm's discovery document must answer from the `tester` pod at `http://keycloak-service:8080/realms/master/.well-known/openid-configuration`.

## Constraints

- **Read every credential from the Secret `keycloak-db` through the `db` fields.** Do not write the user name or the password into the resource, and do not set any database option in `additionalOptions`.
- Do not change the Secret `keycloak-db` or the PostgreSQL Deployment. The database is healthy; the resource is not.
- Do not edit the StatefulSet or the pods by hand. Change the `Keycloak` resource.
- Do not delete and recreate the `Keycloak` resource.

## Done when

- The `Keycloak` resource reports `Ready=True`, and its StatefulSet has one ready pod.
- The database host is `postgres`, and both credentials come from `keycloak-db` (`username`, `password`).
- The discovery document from the `tester` pod names the issuer `http://keycloak-service:8080/realms/master`.
