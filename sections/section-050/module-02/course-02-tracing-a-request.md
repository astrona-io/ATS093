# Tracing A Request

A metric says that token requests have a slow tail. A trace says where one slow request spent its time: in Keycloak, in the database, in a call to a directory, or in a call to an identity provider.

## What a trace is

A trace follows one request. It is made of **spans**, one for each step, with a start and a duration. Keycloak creates spans for:

- Incoming HTTP requests.
- Outgoing database calls, including the wait to get a connection.
- Outgoing LDAP requests, including connecting to the server.
- Outgoing HTTP requests, such as a call to an identity provider.

The spans carry tags prefixed with `kc.`, such as `kc.clientId`, `kc.realmName`, `kc.sessionId` and the id and issuer of a token. With these you can search for all traces of one client or one realm.

## Enable it

Tracing uses OpenTelemetry and needs the `opentelemetry` feature, which is on by default. Switch it on with the option `tracing-enabled`:

```yaml
spec:
  additionalOptions:
    - name: tracing-enabled
      value: "true"
    - name: tracing-endpoint
      value: "http://otel-collector.observability:4317"
```

By default the traces are sent in batches over gRPC to `http://localhost:4317`, which on a pod is nothing. Point the endpoint at an OpenTelemetry collector or a tracing backend such as Jaeger or Tempo. The service name is `keycloak`; set `telemetry-service-name` to tell several instances apart, and `telemetry-resource-attributes` for labels such as the environment.

## Sampling

Tracing every request is costly. A **sampler** decides which traces to keep. The default sampler is `traceidratio`, set with `tracing-sampler-type`, and the ratio in `tracing-sampler-ratio` is `1.0` by default: every trace is sent. That is right for a test cluster and too much for production, where a smaller ratio such as `0.1` keeps one trace in ten. A ratio of `0.0` turns sampling off at runtime. Sampling at the start of a request is cheap but blind; sampling in the collector after the trace is complete can keep the slow and failed ones. Choose by cost and by what you need to find.

## Traces and logs

With `log-console-include-trace` enabled, log records carry the trace and span id of the request that wrote them. In a log store that indexes the field, a slow trace links to the lines it produced, which closes the gap between the two signals. This is the most useful single step after turning tracing on.

## When it helps

Tracing earns its cost when the slow part is outside Keycloak: an LDAP server that answers in two seconds, an identity provider that times out, a database that is slow only for one query. For a problem inside the process, the metrics and a thread dump come first.

## What can go wrong

If the collector is not reachable, Keycloak logs a warning and carries on; it does not stop serving. That is the right behaviour for a signal, and the reason a missing trace is something you notice only if you look. After enabling tracing, send one request and find it in the backend before you rely on it.
