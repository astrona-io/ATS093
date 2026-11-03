# Summary

Availability is a number you choose and then enforce. The tools differ in what they protect against.

## What you learned

Kubernetes splits disruption into voluntary actions, such as a node drain, and involuntary failures. A `PodDisruptionBudget` controls only the voluntary kind through the eviction API. It takes `minAvailable` or `maxUnavailable`, never both, and shows `ALLOWED DISRUPTIONS` in its status. A budget with `minAvailable` equal to the number of pods blocks every drain, and one with `expectedPods` of `0` matches nothing.

Spreading keeps the pods from failing together. Anti-affinity and topology spread constraints in `spec.scheduling` put pods on different nodes and zones, and the operator uses the node name so cache copies land on different machines. Zones help only if the database survives a zone loss too.

The `Keycloak` resource has the scale interface, so `kubectl scale` and a horizontal autoscaler can change `spec.instances`. Every instance adds database connections, memory and cache traffic, so check `max_connections` before you scale. A stopping pod finishes its requests within the grace period, and the readiness probe keeps traffic away from a pod that is not ready. Beyond one site, a multi-site design adds an external Infinispan and a failover that must be tested. The key facts to remember are these:

- A budget stops drains and evictions, not crashes and not `kubectl delete pod`.
- `maxUnavailable: 1` grows with the cluster; `minAvailable` equal to the pod count blocks every drain.
- Spread pods over nodes and zones, and check the database does the same.
- Total database connections are the pool size times the number of pods.

<!-- astrona:playground:destroy -->
