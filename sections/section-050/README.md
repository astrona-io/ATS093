# Section 050: Observability And Troubleshooting

A Keycloak that works is not the same as a Keycloak you can operate. When a login is slow, a pod restarts or a user cannot sign in, the first question is what the server can tell you, and the second is whether you set it up to say it. By default it says very little: the log is plain text, the metrics are off, and no event is recorded.

This section turns on the signals, learns to read them, and practises the order of work when a deployment does not start.

## What you will learn

- The four health endpoints, the probes the operator sets, and why readiness and liveness are different questions.
- Enabling metrics on the management port, the families `jvm`, `agroal` and `http_server`, user event metrics and the `serviceMonitor` block.
- Root, category and handler log levels, JSON console output, and how the events listener writes to the log.
- Which few signals deserve an alert, and why to page on symptoms.
- Login events and administration events, with expirations, and their limits.
- OpenTelemetry tracing: spans, tags, the collector endpoint and sampling.
- Troubleshooting from the outside in: resource conditions, pod events, container log, dependencies, then one change.

## The learning path

The section has two modules. Each has a landing page that starts its playground, short parts, a graded lab right after the part it tests, and a summary. The first playground is a single Keycloak with health and metrics on; the second adds the realm `inventory`.

### 1. Health, Metrics And Logs

1. Health Endpoints And Probes
2. Metrics On The Management Port
3. Logs That Machines Can Read, followed by the lab **Make Keycloak Observable**
4. What To Watch And Alert On
5. Summary

### 2. Events, Tracing And Troubleshooting

1. Events As Signals
2. Tracing A Request
3. A Method For Troubleshooting, followed by the lab **Find Why Keycloak Does Not Start**
4. Common Failures And Their Signs
5. Summary

## Section capstone: Make Keycloak Observable End To End

The capstone starts with a Keycloak that logs everything at `debug` as plain text, serves no metrics, and a realm that records no events. You turn on the metrics, set the logging, record events with an expiration, and prove it by causing a failed login and finding it. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/section-050/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-093-capstone-050
```
