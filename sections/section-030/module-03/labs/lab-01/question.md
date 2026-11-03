# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Hardening the settings of a realm

## Scenario

The realm `inventory` in the namespace `keycloak` was imported with Keycloak defaults. A security review found three gaps: passwords of any length are accepted, nobody can see who signed in or who changed the administration settings, and a refresh token can be used again and again, so a stolen one is useful for a long time.

## Your task

In the realm `inventory`:

1. Require passwords of at least `12` characters, and passwords that differ from the user name.
2. Turn on login events and administration events, and keep the details of administration events.
3. Make refresh tokens single use by revoking them after use.
4. Keep the user `alice` (password `alice-password`) able to sign in.

## Constraints

- Change the realm with `kcadm.sh` or the console. The administrator credentials are in the Secret `keycloak-initial-admin`.
- Do not delete the realm and do not change the users.

## Done when

- The password policy contains `length(12)`, and `bob` cannot be given a six character password.
- `eventsEnabled`, `adminEventsEnabled` and `adminEventsDetailsEnabled` are `true`.
- `revokeRefreshToken` is `true`, and `alice` gets a token.
