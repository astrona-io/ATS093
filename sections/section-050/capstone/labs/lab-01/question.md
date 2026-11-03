# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Making a Keycloak deployment observable end to end

## Scenario

The on-call engineer for Keycloak in the namespace `keycloak` has three complaints. The metrics system gets nothing from Keycloak. The log is full of debug output as plain text, which costs money and cannot be searched by field. And when a user says "I could not sign in", nobody can find the attempt, because the realm `inventory` records no events.

## Your task

1. Make the metrics available on the management port, and keep health working.
2. Set the root log level to `info`, log the category `org.keycloak.events` at `debug`, and write the console log as JSON.
3. Record login events in the realm `inventory`, and let them expire after 7 days (`604800` seconds) so the table does not grow without limit.
4. Show that it works: a failed login must leave a `LOGIN_ERROR` event that you can list.
5. Keep `alice` (password `alice-password`) able to sign in.

## Constraints

- Change the `Keycloak` resource and the realm settings. Do not edit the StatefulSet or the pod by hand.
- `additionalOptions` is replaced as a whole when you patch it, so list every option you want to keep.
- Do not delete the realm and do not change the users.

## Done when

- `/metrics` answers on port `9000` and `/health/ready` returns `200`.
- The pod runs with JSON console output and the level `INFO,org.keycloak.events:debug`.
- Events are on with an expiration of at most 30 days, and a failed login for `alice` is listed as `LOGIN_ERROR`.
- `alice` still gets a token.
