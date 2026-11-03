# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Making Keycloak observable

## Scenario

Keycloak in the namespace `keycloak` is running, but the team that operates it cannot use what it produces. The log is free text that the log collector cannot parse. Login events are written at a level that is never shown. And the metrics system should scrape Keycloak twice as often as the default.

## Your task

In the `Keycloak` resource `keycloak`:

1. Write the console log as JSON.
2. Keep the root log level at `info`, and log the category `org.keycloak.events` at `debug`.
3. Set the interval of the generated ServiceMonitor to `15s`.
4. Keep health and metrics enabled, so that `/health/ready` and `/metrics` answer on the management port.

## Constraints

- Change the `Keycloak` resource. Do not edit the StatefulSet or the pod by hand; the operator would undo it.
- `additionalOptions` is replaced as a whole when you patch it, so list every option you want to keep.
- Do not delete the `Keycloak` resource.

## Done when

- The pod `keycloak-0` runs with the console output set to `json`, and its newest log lines are valid JSON.
- The level is `INFO,org.keycloak.events:debug`.
- Port `9000` answers `/health/ready` with `200` and `/metrics` with metrics, and the ServiceMonitor interval is `15s`.
