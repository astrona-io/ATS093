# Graceful Shutdown And Multi-Site

Pods stop all the time: during a rolling update, a drain or a scale down. A pod that stops badly fails the requests it was serving, and a cluster that lives in one site fails with the site. This part covers both.

## What happens when a pod stops

Kubernetes sends the termination signal to the Keycloak process and removes the pod from the service endpoints. Keycloak stops accepting new connections and finishes the requests in progress. The container then exits. If it has not exited when the grace period ends, Kubernetes kills it.

Two settings decide how well this goes. The first is the grace period, `terminationGracePeriodSeconds` of the pod, which is 30 seconds by default. Requests such as a token call take milliseconds, so the default fits most deployments. A pod that serves long requests needs more. The `Keycloak` resource has no field for it; the pod template override of `spec.unsupported.podTemplate` can set it, with the support caveat of that field.

The second is the readiness probe. A pod receives traffic only while it is Ready. The operator sets the probes on the container for you, and they use the health endpoints on the management port. Keep `health-enabled` set. During a rolling update the StatefulSet replaces one pod at a time and waits for the new pod to be Ready before it moves on. A pod that reports Ready too early takes traffic it cannot serve.

## Read the probes the operator set

```sh
kubectl -n keycloak get statefulset keycloak -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}{"\n"}'
kubectl -n keycloak get statefulset keycloak -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}{"\n"}'
```

Note the path of the probe and the grace period. Together with a budget of `maxUnavailable: 1`, they give a rolling update that keeps at least one pod serving.

## Rolling updates and cache entries

When a pod stops, the entries it owned are moved to the other pods. A pod that stops in a hurry, or two that stop together, can lose entries of the short-lived distributed caches, such as sign-ins in progress. Users see that as a login form that has to be started again. Sessions of signed-in users are in the database, so they survive. This is another reason to roll one pod at a time.

## One site is a limit

A cluster in one data center or one region is gone when that site is gone. Keycloak documents a multi-site setup for that case: two or more sites, each with its own Keycloak cluster, a shared or replicated database, and an external Infinispan that carries the state that must cross sites. A load balancer or DNS level service sends users to a healthy site and fails over when one fails.

The details belong to the high availability guide, and they depend on your platform. The points to know for a design discussion are these:

- The database must work across the sites. Latency between the sites sets how fast every request is.
- Session and login failure data that must cross sites moves out of the embedded caches into an external Infinispan.
- Each site has its own embedded caches, and they must not merge. Cluster names and separate discovery keep them apart.
- A failover must be tested. A design that was never switched over is an assumption.

Treat multi-site as an architecture project with its own testing, not as a setting. Within one site, the budget, the spread and the instance count from this module are the tools.
