# Events, Tracing And Troubleshooting

Metrics say that logins are slow. Logs say that one failed. Neither says why this request took four seconds, who changed the client last night, or why the pod is stuck. Events, traces and a method for reading the system from the outside in answer those.

This module covers the two deeper signals, and then the skill that makes all of them useful: troubleshooting in a fixed order. Keep one sentence in mind: **start at the outside and move in, and change one thing at a time, so that every result tells you something.**

The module has four parts. **Events As Signals** covers login and administration events beyond the log. **Tracing A Request** covers OpenTelemetry. **A Method For Troubleshooting** gives the order of work; a graded lab follows it. **Common Failures And Their Signs** is a field guide to what you will see.

## Learning objectives

After this module you can:

- Choose between the log, the event store and metrics for a question.
- Enable tracing, say what the spans and tags show, and where the data goes.
- Read the conditions of a `Keycloak` resource, the events of a pod and a container log, in that order.
- Use `--previous` to read the log of a container that restarted.
- Recognise the usual failures: missing Secret keys, an unreachable database, a bad hostname, out of memory.
- Fix a resource that does not start without guessing.

## Before you start

You need to know health endpoints, metrics and logs, and how events are turned on in the realm settings.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance on PostgreSQL, health and metrics enabled |
| `inventory` | The realm, with the users `alice` and `bob` and the public client `inventory-cli`; events off |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
