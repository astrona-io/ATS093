# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Finding why Keycloak does not start

## Scenario

A colleague applied a `Keycloak` resource named `keycloak` in the namespace `keycloak` and went home. The resource never became Ready. There is more than one mistake, and the second one only shows after the first is fixed.

## Your task

1. Find out why the pod does not start, using the status of the resource, the pod and its events, and the log. Work from the outside in.
2. Fix every mistake in the `Keycloak` resource until it is Ready.
3. Write down for yourself which command showed each mistake.

## Constraints

- Fix the `Keycloak` resource. Do not create a new database or a new Secret; both exist and are correct.
- The host of the database is correct. Do not change it.
- Do not delete the `Keycloak` resource.

## Done when

- The `Keycloak` resource reports `Ready=True`, and the pod `keycloak-0` is running.
- `db.database` and `db.passwordSecret.key` name the database and the Secret key that exist.
- `/health/ready` on the management port returns `200`.
