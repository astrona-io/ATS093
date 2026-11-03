# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Changing a realm that a KeycloakRealmImport already created

## Scenario

The realm `inventory` in the namespace `keycloak` was created by the `KeycloakRealmImport` named `inventory`. The web team now has an application at `https://inventory.example.com` that must sign users in. The security team also wants longer access tokens for the batch jobs that call the inventory service.

The import file belongs to another team and must stay as it is.

## Your task

In the realm `inventory`:

1. Create a public client with the client ID `inventory-web`, the standard flow enabled, and the redirect URI `https://inventory.example.com/*`.
2. Set the access token lifespan of the realm to `900` seconds.
3. Keep the user `alice` (password `alice-password`) working.

## Constraints

- Do not delete the realm, and do not delete the `KeycloakRealmImport`.
- Change the realm with `kcadm.sh` or the console. Editing the `KeycloakRealmImport` and applying it again changes nothing in an existing realm.
- The administrator credentials are in the Secret `keycloak-initial-admin`.

## Done when

- The client `inventory-web` exists, is public, and has the redirect URI `https://inventory.example.com/*`.
- The realm `inventory` has `accessTokenLifespan` `900`.
- `alice` gets a token, and the `KeycloakRealmImport` `inventory` still exists.
