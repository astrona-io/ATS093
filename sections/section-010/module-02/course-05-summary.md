# Summary

The `Keycloak` resource is the single place that describes the pod, and each field in it has a visible result on the StatefulSet and on the pod. Tuning Keycloak means changing the resource, reading the pod, and finding out why Kubernetes accepted or refused the result.

## What you learned

Resource requests decide where the scheduler may place a pod, and the memory limit decides when the kernel ends the container. The Java heap is a share of the memory limit, so a container without a limit sizes its heap from the node. A pod that is `Pending` shows its reason in the pod events, and a container that was killed shows `OOMKilled` with exit code `137`.

The `scheduling` block carries affinity, tolerations, topology spread constraints and a priority class into the pod template. A spread constraint with `ScheduleAnyway` prefers an even spread and never blocks a start, while `DoNotSchedule` can leave a pod `Pending`. A toleration lets a pod run on a tainted node but does not choose that node.

Server options that have no typed field go in `additionalOptions` by their command-line name without dashes, and the operator turns each into a `KC_` environment variable. A value can come from a Secret with `secret` instead of `value`, which keeps passwords out of the resource. A missing Secret key keeps the container from being created.

A custom image adds providers and themes and runs `kc.sh build` once, and `startOptimized: true` tells the operator to start Keycloak without a new build. The `unsupported.podTemplate` field merges a partial pod template into the generated one and is outside project support. The key facts to remember are these:

- Change the resource, never the StatefulSet.
- The memory limit sets the heap size and the kill point.
- Read the pod, not only the resource, to see what the operator rolled out.
- A new image needs a new tag and `startOptimized: true` when it is built.

<!-- astrona:playground:destroy -->
