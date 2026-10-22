# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** The Keycloak Operator and realm import

## Scenario

The platform team installed the Keycloak Operator in the namespace `keycloak` and prepared PostgreSQL and two Secrets. Then the work stopped. There is no Keycloak yet, and the application team is waiting for the realm `inventory` so that `alice` can sign in.

What is ready for you in the namespace `keycloak`:

| Name | What it holds |
| --- | --- |
| Service `postgres` | PostgreSQL on port `5432`, database `keycloak` |
| Secret `keycloak-db` | Keys `username` and `password` for the database |
| Secret `inventory-secrets` | Key `alice-password`: the first password for `alice` |

## Your task

In the namespace `keycloak`:

1. Create a `Keycloak` resource named `keycloak` with one instance that:
   - uses PostgreSQL at `postgres`, database `keycloak`, with both credentials read from `keycloak-db`;
   - listens on HTTP, with the hostname `http://keycloak-service:8080`;
   - creates no Ingress;
   - sets a memory limit for its pods (at most `1536Mi` fits this machine).
2. Create a `KeycloakRealmImport` named `inventory` for the realm `inventory` with:
   - the user `alice` (enabled, email `alice@example.com` verified, first name `Alice`, last name `Example`), whose password comes from `inventory-secrets` through a placeholder, not temporary;
   - the public client `inventory-cli` with direct access grants on and the standard flow off.
3. Prove it: `alice` gets a token from `inventory-cli` with the password grant from the `tester` pod.

## Constraints

- **No password or user name in either resource.** Database credentials come from `keycloak-db` through the `db` fields; `alice`'s password comes from `inventory-secrets` through `spec.placeholders`.
- Do not change the Secrets or PostgreSQL.
- Do not create the realm with `kcadm.sh` or the console. The realm import must create it.

## Done when

- The `Keycloak` resource `keycloak` is `Ready`.
- The `KeycloakRealmImport` `inventory` reports `Done=True` and `HasErrors=False`.
- A token for `alice` from the realm `inventory` carries the issuer `http://keycloak-service:8080/realms/inventory`.
