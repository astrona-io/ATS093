# Prerequisites

Before starting this lab you should be able to:

- Read why a pod is `Pending` from its events.
- Read the `vendor_cluster_size` metric of a Keycloak pod.
- Change the instances, options and resources of a `Keycloak` resource.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace `keycloak`, the namespace it watches.
- PostgreSQL 17 (`postgres`), the Secrets `keycloak-db` and `inventory-secrets`, and the `tester` pod with `curl` and `jq`.
- A `Keycloak` resource named `keycloak` and the realm `inventory`, prepared as the task describes.

## Working rules

- Everything is graded on the **final state** of the cluster, so leave your fix in place.
- Change one thing at a time and check again. The operator needs a minute or two to roll out each change to the `Keycloak` resource.
- Change the custom resources, not the StatefulSet, Service or Secrets the operator creates. The operator puts its own objects back the way the resource describes them.
- `kubectl` is all you need on your machine. Every Keycloak and PostgreSQL command runs inside a pod with `kubectl exec`.
