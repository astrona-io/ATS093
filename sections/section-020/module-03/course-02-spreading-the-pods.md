# Spreading The Pods

A budget decides how many pods may be missing. Spreading decides which ones go missing together. Two pods on one node are one failure waiting to happen: when the node dies, both are gone, and the budget never had a chance to help.

## Why the node matters for the caches

Keycloak keeps copies of distributed cache entries on different pods. The operator sets the machine name of each pod from its Kubernetes node, so Infinispan prefers to place the copies on different machines. If both pods run on one node, the copies share one machine and the safety is gone. The pods also share the memory and the network of that node.

## Anti-affinity and topology spread

The `scheduling` block of the `Keycloak` resource takes both tools. Anti-affinity says which pods must not share a domain:

```yaml
spec:
  scheduling:
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  app: keycloak
```

`preferred` lets the scheduler break the rule when no other node fits, and `required` makes the pod wait instead. On a three-node cluster, `required` is reasonable. On a cluster that may shrink to fewer nodes than pods, it leaves pods Pending.

Topology spread constraints say how uneven the placement may be, which scales better than anti-affinity when you have more pods than nodes:

```yaml
spec:
  scheduling:
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: keycloak
```

`maxSkew: 1` means no zone has more than one pod more than the emptiest zone. The key `topology.kubernetes.io/zone` spreads over zones, and `kubernetes.io/hostname` over nodes. You can combine both: spread over zones first, then over nodes.

## Zones and the database

Pods in several zones survive the loss of a zone only if the database does. Keycloak in three zones on top of a PostgreSQL in one zone moves the single point of failure from the node to the database. Check the database design before you count the zones as protection. Also keep the pods and the database in the same region: every request does database round trips, and cross-region latency adds up quickly.

## Try it

Read the labels of the pods and the scheduling of the StatefulSet that the operator built:

```sh
kubectl -n keycloak get pods --show-labels
kubectl -n keycloak get statefulset keycloak -o jsonpath='{.spec.template.spec.affinity}{"\n"}{.spec.template.spec.topologySpreadConstraints}{"\n"}'
```

On the single-node playground both pods run on one node, and that is expected. On a real cluster you would see them on different nodes, and you would use `kubectl get pods -o wide` to check.

## Putting the three together

A sound production setup combines the tools: a budget with `maxUnavailable: 1`, topology spread over zones, a preferred anti-affinity over nodes, and an instance count that is larger than the number of failures you plan for. Each tool is cheap on its own, and each one fails alone: the budget does not place pods, the spread does not stop a drain, and neither helps if only one instance exists.
