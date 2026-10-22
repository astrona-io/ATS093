# Section 040: Backup, Restore And Upgrades

Every Keycloak problem in production ends with one of two questions: can we get the data back, and can we go back to the version that worked? Both have the same answer at their centre, the database. Keycloak keeps everything that matters there, and a Keycloak upgrade changes the database schema in a way that cannot be undone by changing the image back.

This section makes backup and restore a routine you have done before you need it, and shows how the Keycloak Operator rolls out a new version and what to do when that goes wrong.

## What you will learn

- What a complete Keycloak backup holds: the database, the custom resources and the Secrets, and why a realm export is not a backup.
- Dumping the database with `pg_dump` and restoring it with `pg_restore` into a new database next to the damaged one.
- Pointing the `Keycloak` resource at the restored database and proving the restore.
- How the operator picks the Keycloak image, the update strategies `RecreateOnImageChange`, `Auto` and `Explicit`, and the `RecreateUpdateUsed` condition.
- Rolling back a failed image change, and restoring data when a rollback alone is not enough.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground: Keycloak with two instances on PostgreSQL, and a realm worth keeping.

### 1. Back Up, Restore And Upgrade Keycloak

1. What To Back Up
2. Dump And Restore The Database, followed by the lab **Restore Keycloak From A Database Dump**
3. Upgrading Keycloak With The Operator
4. Summary

## Section capstone: Recover After A Failed Upgrade

The capstone starts after a bad night: an image change left no Keycloak pod running, and data was lost after the last backup was taken. You roll back the image, choose an update strategy that allows rolling patch updates, and restore the data from the backup. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-093-capstone-040
```
