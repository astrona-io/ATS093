# Health Endpoints And Probes

Kubernetes asks three questions of a container: has it started, is it alive, and can it take traffic? Keycloak has one endpoint for each, and they are separate for a reason. A server that is slow to start must not be killed, a server that is stuck must be, and a server that has lost its database should be left alive but given no traffic.

## The four endpoints

Health checks are enabled with the option `health-enabled`. Keycloak then serves:

| Endpoint | The question | What Kubernetes does with a failure |
| --- | --- | --- |
| `/health/started` | Has the initial start finished? | Keeps waiting; the liveness check does not run yet |
| `/health/live` | Is the process running? | Restarts the container |
| `/health/ready` | Can it serve requests? | Removes the pod from the Service, without a restart |
| `/health` | All checks together | Used by people and scripts |

Each answers `200` with `{"status":"UP"}` when well, and `503` when not. The body lists the checks behind the answer: `Keycloak Initialized`, `Graceful Shutdown`, a cluster check, and a check of the database connection pool. The database check needs metrics to be enabled.

## Where they are served

The endpoints are on the **management interface**, port `9000`, not on `8080`. This keeps them apart from user traffic, so a proxy that forwards `/` does not publish them. The `Keycloak` resource has an `httpManagement` block with the port. If you set `http-management-health-enabled` to `false`, the health endpoints move back to the main port, and then you must block `/health` at the proxy yourself. Keep the default.

If you turn on mutual TLS for the main port with `https-client-auth=required`, the management interface inherits it, and probes without a certificate fail. Set `https-management-client-auth` to `request` or `none` in that case.

## The probes the operator sets

You do not write the probes. The operator puts a startup, a liveness and a readiness probe on the pod, pointing at the endpoints above on port `9000`. The `Keycloak` resource lets you tune them (`startupProbe`, `livenessProbe`, `readinessProbe` with period and failure threshold), which you need when the database is slow and the default start window is too short.

```sh
kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.spec.containers[0].readinessProbe}{"\n"}'
```

## Read the answer yourself

The Keycloak image has no `curl`, so call the pod from another pod:

```sh
POD_IP=$(kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.status.podIP}')
kubectl -n keycloak exec deploy/tester -- curl -s http://$POD_IP:9000/health/ready
```

A failing check names itself in the body, which is the fastest way to tell a lost database from a cluster problem.

## Readiness is not a restart signal

Do not use the readiness endpoint to decide that a container must restart. A database that is down for a minute would make every pod restart together and turn a brief problem into an outage. Readiness takes the pod out of the Service. Liveness restarts it. The operator keeps the two apart; keep them apart in anything you add.

## Graceful shutdown

When a pod is stopped, the `Graceful Shutdown` check starts to answer `DOWN` first. That removes the pod from the Service before it stops, so that requests in flight finish. It is the reason a rolling restart does not drop logins, and the reason a termination grace period is worth setting.
