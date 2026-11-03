# Scaling Keycloak

Adding instances raises the number of requests the cluster handles and the number of failures it survives. It also raises the load on everything the instances share. This part shows how to scale, and what to check before you do.

## Change the number of instances

The number of pods is `spec.instances`. You can edit it, and because the custom resource exposes the standard scale interface you can use `kubectl scale` too:

```sh
kubectl -n keycloak scale keycloak keycloak --replicas=3
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.instances} {.status.instances}{"\n"}'
```

A new pod joins the existing cluster through `jdbc-ping` and receives its share of the distributed cache entries. Scaling down removes the highest-numbered pod. Do it one pod at a time, so the entries that pod owned can move to the others before the next one stops.

## Autoscaling

The scale interface is what a horizontal pod autoscaler needs. It can target the `Keycloak` resource and change `spec.instances` on a metric such as CPU use:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: keycloak
  namespace: keycloak
spec:
  scaleTargetRef:
    apiVersion: k8s.keycloak.org/v2beta1
    kind: Keycloak
    name: keycloak
  minReplicas: 2
  maxReplicas: 4
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

A CPU metric needs resource requests on the pods and a metrics server in the cluster. Keep `minReplicas` at the number you need for availability, never below two. Autoscaling suits load that changes during the day. It reacts in minutes, so it does not replace capacity for a sudden login storm. Test it against real traffic before you rely on it, because every scale-up changes the cluster membership.

## What grows with every instance

| Resource | What happens |
| --- | --- |
| Database connections | Every pod opens its own pool. Total connections are the pool size times the number of pods |
| Memory | Each pod keeps its own local caches and heap |
| Cache traffic | Distributed entries are copied between pods; more pods means more messages |
| Startup | A pod needs time before it is Ready, and the first start of a cluster is the slowest |

The first row causes the most outages. PostgreSQL has a maximum number of connections. If the maximum pool of one pod is 100 and you scale to four pods, you need up to 400 connections plus the ones other applications use. Check `max_connections` before you scale, and consider a pooler in front of the database if the number gets large. The pool fields of the `Keycloak` resource were covered with the database settings.

## Scaling is not always the answer

Slow sign-ins can come from the database, from the password hashing cost, from an external identity provider or from a cache that is too small. More pods help when the CPU of the pods is the limit. Look at CPU use of the pods, the database load and the response time before you add instances.

## Try it

Scale the playground to three instances, watch the pod start and check the cluster size on every pod, then scale back:

```sh
kubectl -n keycloak scale keycloak keycloak --replicas=3
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak scale keycloak keycloak --replicas=2
```

Three pods need about 4.5 GiB of memory on the node. If the third pod stays Pending, read `kubectl -n keycloak describe pod keycloak-2` and look for the memory event, then scale back down.
