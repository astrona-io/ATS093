# Summary

Health, metrics and logs are three views of the same server. Each is useful only when someone or something reads it.

## What you learned

Health has four endpoints on the management port: started, live, ready and the whole. Ready takes a pod out of the Service; live restarts it; do not mix the two. The operator sets the probes, and you tune them when starts are slow. Port `9000` carries health and metrics and stays internal.

Metrics come from `metrics-enabled` and are served at `/metrics`. The families `jvm`, `agroal` and `http_server` show memory, the database pool and request time. User event metrics count activity per instance, and each added dimension multiplies the series. The `serviceMonitor` block sets how Prometheus scrapes.

Logs have a root level, category levels and handler levels; a handler can only be quieter than the root. JSON console output lets a collector read fields. The events listener writes successes at `DEBUG` and failures at `WARN`. Alert on a few symptoms, graph the rest, and test the alerts. The key facts to remember are these:

- Readiness removes traffic; liveness restarts.
- Health and metrics are on port `9000`, never on the public path.
- Raise one category, not the root, to look into a problem.
- Page on symptoms users feel, not on causes.

<!-- astrona:playground:destroy -->
