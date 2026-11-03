# Tune The Keycloak Pods With The Operator

The Keycloak Operator builds the StatefulSet for Keycloak from the `Keycloak` resource. Most of the fields that decide how well Keycloak runs in production live in that resource: how much memory and CPU each pod gets, which nodes the pods may use, which server options are set, and which image runs. A wrong value here rarely gives an error message. It gives a pod that stays `Pending`, a container that the kernel kills, or a server that ignores a setting.

This module goes through those fields one by one. For each one it shows what the operator does with the value, what Kubernetes does with it afterwards, and how to see the result on the pod. Keep one sentence in mind: **the `Keycloak` resource is the only place to change the pod, and the StatefulSet shows what the operator made of it.**

The module has four parts. **Resources And Java Memory** explains requests, limits and how the Java heap follows the memory limit. **Scheduling And Priority** covers `scheduling`: affinity, tolerations, topology spread and priority class. **Server Options And Secrets** covers `additionalOptions`, the log options and how a value comes from a Secret; a graded lab follows it. **Pod Template And Custom Images** covers `unsupported.podTemplate`, the `image` field, providers, themes and `startOptimized`.

## Learning objectives

After this module you can:

- Set `resources.requests` and `resources.limits` and explain how the Java heap size follows the memory limit.
- Read why a pod is `Pending` or `OOMKilled` from `kubectl describe pod`.
- Use `scheduling` to set affinity, tolerations, topology spread constraints and a priority class.
- Set any server option with `additionalOptions`, from a plain value or from a Secret, and set the log format.
- Explain what `unsupported.podTemplate` can change and why the project does not support it.
- Build a custom image with a provider and use it with `image` and `startOptimized`.

## Before you start

You need to know what a StatefulSet, a pod and a node are, and how `kubectl describe` and `kubectl logs` work. You do not need to know Java or Quarkus; each option is explained where it is used.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance, explicit resources, a spread constraint, a priority class and a JSON console log |
| `inventory` | A `KeycloakRealmImport` that created the realm `inventory` with the user `alice` |
| `postgres` | PostgreSQL 17, the database Keycloak uses |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
