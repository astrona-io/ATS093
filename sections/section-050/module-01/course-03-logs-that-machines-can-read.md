# Logs That Machines Can Read

Logs are what you read last and need most. Two things make them useful in production: the right amount, and a format that a collector can split into fields.

## Levels

From quiet to loud the levels are `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE`; `ALL` and `OFF` are the extremes. The default root level is `info`. The option `log-level` sets it, and it also takes categories in a comma-separated list:

```yaml
- name: log-level
  value: "INFO,org.keycloak.events:debug"
```

This reads: everything at `INFO`, and the category `org.keycloak.events` at `DEBUG`. A category applies to its sub-categories unless a more specific one is listed. Raise the level for the area you are looking into, not for the whole server. A root level of `debug` in production writes enough to fill a disk and slows the server down.

You can also set a category on its own with the option `log-level-<category>`, for example the variable `KC_LOG_LEVEL_ORG_KEYCLOAK`. It takes precedence over `log-level`, so you can change one area without rewriting the list.

## Handlers

Logs go to handlers: `console` (the default), `file` and `syslog`. Choose them with `log`. In Kubernetes, write to the console and let the platform collect it; a file inside a container is lost when the container is.

Each handler has its own level, such as `log-console-level`. A handler level only restricts: the root level is the most verbose the whole system can be, and a handler can be quieter than it, never louder. If the root is `info`, setting `log-console-level=debug` shows nothing new.

## JSON output

A plain log line is written for people. A collector must guess where the time, the level and the message start, and a multi-line stack trace becomes many unrelated lines. The option `log-console-output=json` writes one JSON object per record, with the time, the level, the logger, the message and the thread as fields, and a stack trace inside one record. The collector indexes the fields and you can search for `level=ERROR` instead of a pattern.

```yaml
- name: log-console-output
  value: "json"
```

The format `ecs`, set with `log-console-json-format`, follows the Elastic Common Schema for those who use it. `log-service-name` and `log-service-environment` add the name of the service and its environment to every record, which separates several Keycloaks in one log store.

With `log-mdc-enabled`, the mapped diagnostic context adds fields such as the realm and client to the records written while a request is handled. That turns "an error happened" into "an error happened for this realm and client".

## The events in the log

Keycloak records events (they must be enabled in the realm settings). The default listener, `jboss-logging`, writes them to the log: failures at `WARN` and successful events at `DEBUG`. So a successful login is invisible at `INFO`, and a failed login is a warning. Raising only the category `org.keycloak.events` to `debug` shows all of them without opening the whole server to debug output.

## Mission

Keycloak writes plain text, its events are hidden at `info` and its metrics are scraped every 30 seconds. In the graded lab you write the console log as JSON, give the events category its own level, and set a faster scrape interval, then check that health and metrics still answer.

<!-- astrona:playground:renew -->
