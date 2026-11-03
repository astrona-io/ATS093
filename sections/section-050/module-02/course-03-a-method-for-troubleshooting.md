# A Method For Troubleshooting

When Keycloak does not work, the temptation is to change something. Resist it. Each change you make before you understand the problem adds a second problem. Read first, from the outside in.

## The order

1. **The custom resource.** `kubectl get keycloak keycloak -o yaml`, and read `status.conditions`. The operator writes what it found: `Ready`, `HasErrors` and `RollingUpdate`, with a message.
2. **The Kubernetes objects.** `kubectl get pods`, `kubectl get statefulset keycloak`. Is there a pod? What is its state?
3. **The pod.** `kubectl describe pod keycloak-0`, and read the **Events** at the bottom. A pod that cannot start tells you why here: a missing Secret key, an image that cannot be pulled, a volume that cannot be mounted, no node with enough memory.
4. **The container log.** `kubectl logs keycloak-0`. For a container that restarted, `--previous` shows the log of the run that died, which is the one that explains it.
5. **The dependencies.** The database, the Secrets, the network. Can the pod reach `postgres`? Does the database exist?
6. **The change.** Only now, one change, and a check.

Each step narrows the problem. The state of the resource points at the pod, the pod at the log, the log at the dependency.

## Read the state, not the first line

```sh
kubectl -n keycloak get keycloak keycloak \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.message}{"\n"}{end}'
kubectl -n keycloak describe pod keycloak-0 | tail -20
kubectl -n keycloak logs keycloak-0 --tail=30
kubectl -n keycloak logs keycloak-0 --previous --tail=30
```

A message like `CreateContainerConfigError` is in the pod state and the events, not in the log, because the container never started. A message like `FATAL: database "x" does not exist` is in the log, not in the events, because the container did start. Knowing which layer reports a failure tells you where to look first.

## Fix, then wait for the right signal

After a change to the `Keycloak` resource, the operator updates the StatefulSet, and the pod is replaced. Wait for the condition `Ready`, not for a fixed time. A pod that never became Ready can keep the old template; if the new revision does not roll, delete the pod and the StatefulSet creates one from the new template.

Two mistakes can hide behind each other. The first stops the pod before it can show the second. Expect to repeat the loop, and do not assume that the second failure means the first fix was wrong.

## Keep notes

Write down what you saw, what you changed and what happened. It is the only way to undo a change that did not help, and it becomes the incident record afterwards.

## Do not do this

- Do not delete and recreate the resource as a first step. You lose the evidence in the status and the events.
- Do not edit the StatefulSet by hand. The operator reconciles it back.
- Do not raise the log level to `trace` for the whole server to "see more". Raise one category.
- Do not restart pods in a loop to see whether it goes away.

## Mission

A `Keycloak` resource was applied and never became Ready, and it has more than one mistake. In the graded lab you work from the resource to the pod to the log, find each mistake, fix the resource, and bring it to Ready.

<!-- astrona:playground:renew -->
