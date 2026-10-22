# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Upgrades and restore

## Scenario

Last night's change in the namespace `keycloak` had two parts. First someone "cleaned up" and deleted the realm `restore-check`, after the nightly dump had already run. Then they upgraded Keycloak by setting an image tag in the `Keycloak` resource. Since then no Keycloak pod has run.

The nightly dump, taken before both changes, is at `/backup/keycloak.dump` in the `postgres` pod. The operator in this namespace is version 26.8.1, and its default image is `quay.io/keycloak/keycloak:26.8.1`.

## Your task

In the namespace `keycloak`:

1. Find out why no Keycloak pod runs, and get Keycloak running again on `quay.io/keycloak/keycloak:26.8.1`.
2. Set the update strategy so that future patch upgrades roll pod by pod instead of stopping every pod first.
3. Bring the realm `restore-check` back from the dump: restore it into a new database `keycloak_restored` and point Keycloak at it.
4. Prove it: the realm `restore-check` answers, and `alice` (password `alice-password`) gets a token from `inventory-cli`.

## Constraints

- **Keep the damaged database `keycloak`** next to the restored one.
- Do not recreate `restore-check` by hand; it must come from the dump.
- Do not reinstall the operator, and change the `Keycloak` resource rather than the StatefulSet.

## Done when

- `keycloak-0` runs `quay.io/keycloak/keycloak:26.8.1`, and the `Keycloak` resource is `Ready`.
- `spec.update.strategy` is `Auto`.
- The `Keycloak` resource uses `keycloak_restored`, and PostgreSQL still has `keycloak`.
- The realm `restore-check` answers, and `alice` gets a token.
