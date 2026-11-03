# Export, Import And Migrate Realms

A realm is the unit you move. You move it from a laptop to a test cluster, from test to production, from one Keycloak to a new one, or from a file in version control into an empty server. Keycloak has several ways to do it, and each leaves different things behind: some leave out the users, some hide the secrets, some only work on a stopped server.

This module teaches which export fits which job, what the file does and does not hold, and how to turn an export into something you can safely keep and import again. Keep one sentence in mind: **an export is a description of a realm, not a copy of a database, so know what is missing before you rely on it.**

The module has four parts. **The Ways To Export And Import** compares the partial export, the offline export and import, and the operator's realm import. **Working With The Export File** shows what is masked and how to make the file safe to store; a graded lab follows it. **Migrating Between Environments** covers what changes from one environment to the next. **Planning An Upgrade** shows how to rehearse a version change on a copy.

## Learning objectives

After this module you can:

- Choose between a partial export, an offline export and a `KeycloakRealmImport`.
- Say what a partial export leaves out or masks, and what an offline export adds.
- Turn an export into a file with placeholders that can be kept in version control.
- Explain why an import does not update a realm that already exists.
- List what differs between environments and handle each difference.
- Rehearse an upgrade on a restored copy before touching production.

## Before you start

You need to know how the database is backed up, and to know what a realm, a client and a role are.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance on PostgreSQL |
| `inventory` | The realm, with the users `alice` and `bob`, the role `auditor`, the group `ops`, the public client `inventory-cli` and the confidential client `inventory-api` |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
