# What To Watch And Alert On

Hundreds of series are available. An alert on all of them is an alert on none of them, because a page that fires too often is soon ignored. Pick a few signals that mean a user is hurt or soon will be, and graph the rest.

## Four questions

1. **Is it up?** The readiness of each pod, and the number of ready pods compared with the number you expect.
2. **Is it fast enough?** The duration of requests to the token endpoint and the login pages, as a high percentile rather than an average.
3. **Is it failing?** The share of responses with a `5xx` status, and the rate of failed logins.
4. **Is it about to run out?** Heap after garbage collection, the connection pool, and disk or memory limits.

## Signals worth a page

| Signal | Why it matters |
| --- | --- |
| Fewer ready pods than `spec.instances` for several minutes | Capacity is lost, and the next failure is an outage |
| Rate of `5xx` responses above a small share of requests | Users are seeing errors |
| 95th percentile of token requests above a limit you set | Applications will time out |
| Connection pool at its maximum with requests waiting | The database or the pool size is the bottleneck |
| Heap after garbage collection above 85 percent | The next growth is an out-of-memory restart |
| Container restarts, rising | Something kills the pod: memory, probes or a crash |

## Signals worth a graph

Logins per realm, failed logins, token refreshes, cache hit rates, garbage collection time, and request rates by route. They explain an alert when it fires and show a trend before it does. A spike in failed logins is not an outage, but it is the first sign of a guessing attack, and it belongs on a dashboard next to the brute force settings.

## Alert on symptoms

An alert on the cause (CPU above 80 percent) pages people for things that harm no one. An alert on the symptom (token requests are slow, logins fail) pages them when users are hurt. Keep cause metrics for the dashboard, where they help to find the reason. For each alert, write what the person on call should do first.

## Check the checks

Test an alert once. Stop a pod, fill a pool, and see that the alert reaches a person. An alert that has never fired is an untested assumption, as a backup that has never been restored is.

## Logs as a signal

A log line can be an alert too. Count records at `ERROR`, and watch for the messages that mean specific trouble: database connection failures, a cluster that has split, and out-of-memory errors. JSON logs make this a field match. Pair it with the events: a burst of `LOGIN_ERROR` events from one address is worth a rate limit at the proxy.
