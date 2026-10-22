# Deploy Keycloak With The Operator

A team that runs Keycloak on Kubernetes by hand writes a StatefulSet, two Services, probes, Secrets and an import Job, and then keeps all of them in step with each Keycloak release. The Keycloak Operator does this work instead. An operator is a controller that runs in the cluster and manages one application through custom resources. You describe the server you want in one `Keycloak` resource, and the operator creates and maintains everything else.

This module teaches you to work through that one resource. Keep one sentence in mind: **you change the custom resource, and the operator changes the cluster.** When something does not start, the answer is in the resource's status conditions, in the events of the objects the operator created, and in the Keycloak log.

The module has three parts. **What The Keycloak Operator Manages** looks at the operator itself and at every object it creates for one `Keycloak` resource. **The Keycloak Custom Resource** goes through the fields every deployment needs, the status conditions, and the initial admin Secret; a graded lab follows it. **Importing Realms With KeycloakRealmImport** creates a realm the operator way and keeps its passwords in a Secret.

## Learning objectives

After this module you can:

- Install the Keycloak Operator and say which namespace it watches.
- List the objects the operator creates for one `Keycloak` resource, and say which ones you must never edit by hand.
- Write a `Keycloak` resource with instances, database, HTTP, hostname, ingress and resources.
- Read the `Ready` and `HasErrors` conditions and follow a failure to the StatefulSet events and the pod log.
- Sign in with the initial admin Secret the operator creates.
- Create a realm with a `KeycloakRealmImport` and explain why it never updates an existing realm.
- Keep a password out of a realm import with a placeholder that reads a Secret.

## Before you start

You need Kubernetes basics: namespaces, StatefulSets, Services, Secrets, custom resources, and the commands `kubectl get`, `kubectl describe`, `kubectl logs`, `kubectl apply` and `kubectl exec`. You also need to know what a Keycloak realm, user and client are.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak-operator` | The Keycloak Operator 26.8.1 |
| `keycloak` | A `Keycloak` resource with one instance; the operator runs it as the pod `keycloak-0` behind the Service `keycloak-service` on port `8080` |
| `inventory` | A `KeycloakRealmImport` that created the realm `inventory` with the user `alice` and the client `inventory-cli` |
| `postgres` | PostgreSQL 17, the database Keycloak uses |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

The first start pulls several large images and can take up to ten minutes. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
