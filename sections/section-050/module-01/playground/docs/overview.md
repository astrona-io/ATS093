# Overview: Health, Metrics And Logs (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator and deploys one Keycloak, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance of Keycloak 26.8.1 on PostgreSQL, with health and metrics on |
  | `postgres` | PostgreSQL 17 with the database `keycloak` |
  | `tester` | Client pod with `curl` and `jq` |

## Helper

Paste this in a new terminal. It prints the IP address of the Keycloak pod, which is where port `9000` answers.

```sh
POD_IP=$(kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.status.podIP}')
```

## Practice tasks

- Call the four health endpoints from the tester pod: `kubectl -n keycloak exec deploy/tester -- curl -s http://$POD_IP:9000/health`, then `/health/started`, `/health/live` and `/health/ready`.
- Read the metrics: `curl -s http://$POD_IP:9000/metrics | grep -c .`, then pick out `agroal_`, `jvm_memory` and `http_server_requests`.
- Look at the probes the operator put on the pod with `kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.spec.containers[0].readinessProbe}'`.
- Read the log with `kubectl -n keycloak logs keycloak-0 | head`. Add `log-console-output` with the value `json` to `additionalOptions` and read it again.
- Check that port `8080` does not serve `/metrics`: `curl -s -o /dev/null -w "%{http_code}\n" http://keycloak-service:8080/metrics`.
