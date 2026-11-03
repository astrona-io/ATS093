# Manage Realms And Clients Declaratively

A Keycloak server is useful only once it holds realms, clients and users. On Kubernetes you can create them in three ways: with a custom resource that the operator turns into an import, with the Admin REST API, or by hand in the administration console. Each way has a different answer to one question that decides everything in production: what happens when the same thing is applied a second time?

This module compares the ways. It starts with `KeycloakRealmImport` and what its job really does, then changes a realm that already exists, then shows the client resources of the operator, and ends with the rules that keep the configuration of many environments in step. Keep one sentence in mind: **an import creates, the Admin REST API changes, and a custom resource describes what should exist.**

The module has four parts. **How A Realm Import Works** follows the import job from the resource to the realm. **Changing A Realm That Exists** uses `kcadm.sh` and the partial import endpoint; a graded lab follows it. **Client Resources** covers `KeycloakOIDCClient` and `KeycloakSAMLClient`. **Configuration Across Environments** covers placeholders, secrets and drift.

## Learning objectives

After this module you can:

- Explain what the import job does and why a second import of the same realm changes nothing.
- Read the `Done` and `HasErrors` conditions of a `KeycloakRealmImport`.
- Change an existing realm with `kcadm.sh` and with a partial import, and choose between `SKIP`, `OVERWRITE` and `FAIL`.
- Describe the fields of the `KeycloakOIDCClient` resource and why `realm` and `keycloakCRName` cannot change.
- Keep passwords out of an import with placeholders that read a Secret.

## Before you start

You need to know what a realm, a client and a user are in Keycloak, and how to read a Kubernetes custom resource with `kubectl get -o yaml`.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance on PostgreSQL |
| `inventory` | A `KeycloakRealmImport` that created the realm `inventory` with the user `alice` and the public client `inventory-cli` |
| `postgres` | PostgreSQL 17, the database Keycloak uses |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
