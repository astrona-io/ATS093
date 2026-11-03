# Health, Metrics And Logs

You cannot run what you cannot see. A Keycloak that works today tells you nothing about tomorrow, unless it also tells you how many logins it served, how full its database pool is, how much memory is left, and what it wrote when something went wrong. Keycloak can say all of this. It only says it if you ask, and where it says it matters.

This module covers the three signals that every Kubernetes workload gives: health, metrics and logs. Keep one sentence in mind: **a signal is only worth having when something reads it, so decide who reads each one before you switch it on.**

The module has four parts. **Health Endpoints And Probes** covers the endpoints and the probes the operator sets. **Metrics On The Management Port** covers where the numbers are and what is in them. **Logs That Machines Can Read** covers levels, categories and JSON output; a graded lab follows it. **What To Watch And Alert On** turns the signals into a short list of things worth a page.

## Learning objectives

After this module you can:

- Name the four health endpoints and say which probe uses which.
- Explain why health and metrics live on port `9000` and must not be public.
- Enable metrics, read them and say what the families `agroal`, `jvm` and `http` describe.
- Set the root log level, a category level and a handler level, and know how they combine.
- Write the console log as JSON and say why a collector prefers it.
- Pick the few signals that deserve an alert.

## Before you start

You should know that port `9000` is kept internal. You should know what a probe and a Service are.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance on PostgreSQL, health and metrics enabled |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
