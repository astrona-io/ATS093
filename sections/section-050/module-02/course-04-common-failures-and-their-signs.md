# Common Failures And Their Signs

Most Keycloak problems on Kubernetes come from a short list. This part is a field guide: what you see, which layer shows it, and what it usually means.

## Pod will not start

| Sign | Layer | Usual cause |
| --- | --- | --- |
| `CreateContainerConfigError` | Pod events | A Secret or ConfigMap, or a key in it, does not exist |
| `ImagePullBackOff` | Pod events | A wrong image name or tag, or no pull credentials |
| `Pending` with `Insufficient memory` | Pod events | The requests do not fit on any node |
| `Pending` with an unbound volume | Pod events | A storage class is missing |

The fix is in the resource or its Secrets. The log is empty because the container never started.

## Pod starts and then fails

| Sign | Layer | Usual cause |
| --- | --- | --- |
| `database "x" does not exist` | Log | The wrong name in `db.database` |
| `password authentication failed` | Log | The wrong user or password in the Secret |
| `Connection refused` or a timeout to the database | Log | The wrong host or port, a network policy, or the database is down |
| `OOMKilled` as the last state | Pod status | The memory limit is lower than the heap and native memory need |
| Restarts with a healthy log | Probes | The startup window is shorter than a slow start |

The log of the failed run, shown by `--previous`, holds the reason.

## Pod runs but users have trouble

| Sign | Layer | Usual cause |
| --- | --- | --- |
| Redirect to `http://` or the Service name | Behaviour | The hostname or the proxy headers are not set |
| `Invalid parameter: redirect_uri` | Page and event | The client does not list that redirect |
| `Not ready` on `/health/ready`, other pods fine | Health | The pod lost its database or its cluster |
| Slow logins, pool at maximum | Metrics | The database is slow or the pool is too small |
| Users signed out after a restart | Behaviour | Sessions are held only in memory |

## Realm import problems

A `KeycloakRealmImport` runs as a Job. If the realm does not appear, look at the Job and its pod: `kubectl get job,pods` and the log of the import pod. An invalid field in the realm document or a missing placeholder Secret stops the Job. An import never changes a realm that already exists, so a change to the resource of an existing realm does nothing.

## The operator itself

If the `Keycloak` resource has no status at all, the operator is not running or does not watch the namespace. Check its Deployment and its log in the operator namespace. A resource applied in a namespace the operator does not watch is accepted by the API and ignored, with no error.

## Use the signals together

The fastest diagnoses combine them. A metric shows the pool at maximum; a trace shows the slow query; an event shows nothing unusual; the log shows a lock wait in the database. No single view would have found it, and each narrowed the next.

## Before you ask for help

Collect what the person helping will ask for: the `Keycloak` resource, with Secrets removed; the conditions; the pod events; the log of the failing run; and the version of the operator and Keycloak. That short bundle saves a round trip.
