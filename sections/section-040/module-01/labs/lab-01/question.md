# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Backup and restore

## Scenario

An administrator cleaned up "test data" in Keycloak this morning, in the namespace `keycloak`. The realm `restore-check` and the user `alice` in the realm `inventory` were not test data. Both are gone from the live database.

Last night's backup ran before the clean-up: a `pg_dump` archive of the database `keycloak` is at `/backup/keycloak.dump` in the `postgres` pod. PostgreSQL runs as `postgres`, with the database user `keycloak`.

## Your task

In the namespace `keycloak`:

1. Restore the dump into a **new** database named `keycloak_restored`.
2. Point the `Keycloak` resource at `keycloak_restored`, and wait until every Keycloak pod runs against it.
3. Prove the restore: the realm `restore-check` answers again, and `alice` (password `alice-password`) gets a token from `inventory-cli`.

## Constraints

- **Keep the damaged database `keycloak`.** Do not drop it and do not restore over it. The team needs it to compare what changed after the dump.
- Do not recreate the realm or the user by hand, with `kcadm.sh`, the console or a realm import; they must come from the dump.
- Change the `Keycloak` resource, not the StatefulSet.

## Done when

- The `Keycloak` resource uses the database `keycloak_restored` and is `Ready`.
- PostgreSQL has both `keycloak` and `keycloak_restored`.
- `http://keycloak-service:8080/realms/restore-check/.well-known/openid-configuration` answers `200`.
- `alice` gets a token from the realm `inventory`.
