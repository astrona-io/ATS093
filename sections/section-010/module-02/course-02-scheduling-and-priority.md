# Scheduling And Priority

With one node, the scheduler has no choice. With many nodes, it has: it can put all Keycloak pods on the same node, or on nodes that are small, or on nodes that are shared with less important workloads. The `scheduling` block of the `Keycloak` resource gives the scheduler the rules. This part shows each field and how to check that the rule reached the pod.

## Where scheduling rules go

`spec.scheduling` holds the same fields as the pod spec, and the operator copies them into the pod template of the StatefulSet:

| Field | What it does |
| --- | --- |
| `affinity` | Rules that attract the pod to nodes or to other pods (`nodeAffinity`, `podAffinity`) or keep it away from other pods (`podAntiAffinity`) |
| `tolerations` | Lets the pod run on nodes that have a matching taint, which normally keeps pods away |
| `topologySpreadConstraints` | Spreads the pods of one workload evenly over nodes or zones |
| `priorityClassName` | Names a PriorityClass; a higher priority lets the scheduler move lower priority pods out of the way |

Read the block in your playground:

<!-- astrona:playground:renew -->

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.scheduling}{"\n"}'
```

It holds a spread constraint with `maxSkew: 1` on `kubernetes.io/hostname`, and `priorityClassName: system-cluster-critical`.

## Spread pods over nodes

A topology spread constraint tells the scheduler to keep the number of matching pods in each topology domain (a node, a zone) within `maxSkew` of each other. The `topologyKey` names the node label that defines the domain; `kubernetes.io/hostname` makes each node one domain, and `topology.kubernetes.io/zone` makes each zone one. `whenUnsatisfiable: ScheduleAnyway` lets the scheduler place the pod even if the rule cannot be met, and `DoNotSchedule` leaves the pod `Pending` instead. The `labelSelector` picks which pods count; the operator labels the Keycloak pods with `app: keycloak`.

For a Keycloak cluster this matters because two instances on one node fail together when the node fails. The same goal can be reached with `podAntiAffinity`, which is stricter: it can forbid two Keycloak pods on one node. Use `ScheduleAnyway` or a `preferredDuringScheduling` rule when you want Keycloak to start even on a cluster that is too small to satisfy the rule.

## Taints and priority

A taint on a node repels every pod that does not tolerate it. Platform teams use taints to reserve nodes. Add a toleration in `scheduling.tolerations` to let Keycloak run on them. A toleration only allows the pod on the node; it does not attract it. Combine it with `nodeAffinity` to require the reserved nodes.

A PriorityClass gives a pod a number. When a node is full, the scheduler can evict pods with a lower number to place a pod with a higher one. Set `priorityClassName` for Keycloak when it must not wait behind batch jobs. A priority class that does not exist leaves the pod unable to be created, with an error in the StatefulSet events.

## Check the result on the pod

The rules are only useful if they reach the pod. Read them from the pod, not from the resource:

```sh
kubectl -n keycloak get pod keycloak-0 \
  -o jsonpath='{.spec.priorityClassName}{"\n"}{.spec.topologySpreadConstraints}{"\n"}'
```

The pod shows the same priority class and the same constraint. If a rule is missing, the operator has not rolled the change out yet, or the pod is an old one that was never replaced.

You can now place Keycloak pods on purpose. What is left is the server itself: its options, and where a secret value comes from.

## Common pitfalls

> [!WARNING]
> - **Using `DoNotSchedule` on a cluster with too few nodes.** The pod stays `Pending` with a message about unsatisfied constraints.
> - **Using a toleration as if it were a node selector.** It allows the node; it does not choose it.
> - **Naming a PriorityClass that does not exist.** The pod is refused when the StatefulSet tries to create it.
> - **Reading the rule from the resource only.** An old pod that never became ready keeps its old template until it is deleted.
