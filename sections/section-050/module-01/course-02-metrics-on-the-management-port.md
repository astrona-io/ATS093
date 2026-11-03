# Metrics On The Management Port

Health tells you that something is wrong. Metrics tell you how it is going: how many connections are in use, how much heap is free, how many requests ran and how long they took.

## Switch them on

Metrics are enabled with the option `metrics-enabled`, which is a build option. With the operator you set it in `additionalOptions` and the operator handles the build:

```yaml
spec:
  additionalOptions:
    - name: metrics-enabled
      value: "true"
```

They are served at `/metrics` on the management port `9000`, in the Prometheus text format. Like the health endpoints, they are never on port `8080` and must never be routed through the proxy.

```sh
kubectl -n keycloak exec deploy/tester -- curl -s http://$POD_IP:9000/metrics | head -20
```

## What is in them

The names start with the part of the system that produced them:

| Prefix | What it describes |
| --- | --- |
| `jvm_` and `base_` | Memory, garbage collection, threads and the process |
| `agroal_` | The database connection pool: active, available and waiting connections |
| `http_server_` | Requests by method, route and status, with their duration |
| `vendor_` | Cache and other component metrics |
| `process_`, `system_` | CPU, load and start time |

Three of them tell you most of what you need. Memory after garbage collection shows whether the heap is too small. The connection pool shows whether the database is the bottleneck: a pool that sits at its maximum, with waiting requests, is the first sign of a slow database. The request duration by route shows which endpoint got slow.

## Cache metrics

The embedded caches report their size and hit rates. The option `cache-metrics-histograms-enabled` adds histograms for them. Histograms cost memory and storage, so turn them on when you are looking for a problem, not by default.

## User event metrics

Keycloak can count what users do: logins, failed logins, token refreshes. These come from the events, as counters, one per realm by default.

```yaml
- name: metrics-enabled
  value: "true"
- name: event-metrics-user-enabled
  value: "true"
```

The option also needs the feature `user-event-metrics` to be enabled in your version. You can limit which events are counted with `event-metrics-user-events`, and add the dimensions `clientId` and `idp` with `event-metrics-user-tags`. Each dimension multiplies the number of series, so add them only where the number of clients is small; Keycloak stops creating new series at 10,000 distinct tag values and logs a warning once. The counters belong to one instance and reset when it restarts, so the monitoring system must sum across pods.

## Getting the numbers to Prometheus

The `Keycloak` resource has a `serviceMonitor` block. With the Prometheus Operator installed, the operator creates a `ServiceMonitor` that tells Prometheus to scrape the management port. The block holds the `interval`, which is 30 seconds by default, the `scrapeTimeout`, which is 10 seconds, and labels and annotations. A shorter interval gives finer graphs and more load; match it to how fast you want an alert to fire.

```yaml
spec:
  serviceMonitor:
    interval: 15s
```

## Keep the port internal

The metrics reveal the number of users, the clients in use and internal timings. Restrict port `9000` with a network policy so that only the monitoring system reaches it.
