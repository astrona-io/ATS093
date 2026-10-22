# Back Up, Restore And Upgrade Keycloak

A Keycloak backup that has never been restored is a hope, not a backup. The restore is where the real questions appear: which database do you restore into, how does Keycloak find it, what about the data written after the dump, and what happens to the sessions? The same goes for upgrades. Changing an image tag takes one line, and the hard part is knowing what the operator will do with it and how to get back.

This module walks through both, on a live cluster. Keep one sentence in mind: **the database is Keycloak's state, and everything else can be rebuilt from files.** A backup is a database dump plus the files that describe the deployment; a restore is a new database plus one changed field in the `Keycloak` resource.

The module has three parts. **What To Back Up** sorts Keycloak's state into what must be backed up and what can be rebuilt. **Dump And Restore The Database** takes a `pg_dump`, restores it next to the original and points Keycloak at it; a graded lab follows it. **Upgrading Keycloak With The Operator** explains how the operator chooses the image and rolls out a change, and why a rollback after an upgrade may need the backup.

## Learning objectives

After this module you can:

- List the parts of a complete Keycloak backup, and explain why a realm export is not one of them.
- Dump the Keycloak database with `pg_dump` and copy the dump off the cluster.
- Restore a dump into a new database with `pg_restore`, without touching the original.
- Point a `Keycloak` resource at a restored database and prove the restore with data that was lost.
- Explain the update strategies `RecreateOnImageChange`, `Auto` and `Explicit`, and read the `RecreateUpdateUsed` condition.
- Roll back an image change in the `Keycloak` resource, and explain when data must be restored as well.

## Before you start

You need to know what a `Keycloak` resource is (the custom resource from which the Keycloak Operator creates the Keycloak StatefulSet) and how its `db` block points at the database. Basic SQL and the idea of a database dump help, but each PostgreSQL command is explained where it is used.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with **two instances** on PostgreSQL |
| `inventory` | The realm, with the user `alice` (password `alice-password`) and the public client `inventory-cli` |
| `restore-check` | A second realm, created only so you can see whether a restore brought it back |
| `postgres` | PostgreSQL 17 with the database `keycloak`; the pod has an empty folder `/backup` for dump files |
| `tester` | A client pod with `curl` and `jq` |

The data in PostgreSQL lives on an `emptyDir` volume, so it lasts as long as the `postgres` pod. Do not delete that pod; it holds the only copy. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
