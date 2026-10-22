# Section 010: Running Keycloak With The Keycloak Operator

On Kubernetes you rarely write the StatefulSet, Services and Secrets for Keycloak yourself. The Keycloak Operator writes them for you from one short custom resource, and it keeps them that way. That saves work, but it also moves the place where things go wrong: a typo in the `Keycloak` resource shows up as a pod that never starts, several steps away from the line that caused it.

This section teaches you to work through the operator. You install it, read what it creates, write the `Keycloak` resource that describes your server, and read the status conditions the operator reports back. You also create a realm the operator way, with a `KeycloakRealmImport`, and keep its passwords in a Kubernetes Secret instead of in the resource.

## What you will learn

- What the Keycloak Operator installs, which namespace it watches, and which objects it creates for one `Keycloak` resource.
- The fields of the `Keycloak` resource that every deployment needs: instances, database, HTTP, hostname, ingress and resources.
- Reading the `Ready` and `HasErrors` conditions, the StatefulSet events and the pod log to find why a deployment does not start.
- The initial admin Secret the operator creates, and how to use it with `kcadm.sh`.
- Creating a realm with `KeycloakRealmImport`, why it never updates an existing realm, and how placeholders keep passwords in a Secret.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground: a cluster where the operator already runs one working Keycloak with the realm `inventory`.

### 1. Deploy Keycloak With The Operator

1. What The Keycloak Operator Manages
2. The Keycloak Custom Resource, followed by the lab **Fix A Keycloak Resource That Never Becomes Ready**
3. Importing Realms With KeycloakRealmImport
4. Summary

## Section capstone: Deploy Keycloak And Its Realm With The Operator

The capstone gives you a cluster with the operator, PostgreSQL and the Secrets, and no Keycloak at all. You write the `Keycloak` resource and the `KeycloakRealmImport` from scratch, so that `alice` can sign in to `inventory` and no password appears in either resource. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-093-capstone-010
```
