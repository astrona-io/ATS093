# Summary

Keycloak's state is its database, and everything else can be rebuilt from files. A backup you can trust is a database dump you have restored before, and an upgrade you can undo starts with one.

## What you learned

A complete backup has three parts. The database holds realms, clients and their secrets, users and their password hashes, the realm signing keys and the user sessions; it is backed up with a dump. The `Keycloak` and `KeycloakRealmImport` resources describe the deployment and belong in Git, saved without their `status`. The Secrets they point at belong in a secret store. A realm export is not a backup: the Admin Console's partial export leaves users out and masks secrets, and no export holds sessions.

`pg_dump -Fc` writes a consistent dump of the live database into a compressed archive, which must be copied off the cluster to survive the loss of the database pod. A restore goes into a new database next to the damaged one, with `createdb` and `pg_restore --no-owner`, so the original stays available for comparison. Keycloak switches over when `spec.db.database` changes and every pod has restarted. Everything written after the dump is not in the restore.

The operator runs the Keycloak image it carries in `RELATED_IMAGE_KEYCLOAK` unless `spec.image` overrides it, so upgrading the operator is the normal way to upgrade Keycloak. `spec.update.strategy` decides the rollout: `RecreateOnImageChange` (the default) stops all pods on an image change, `Auto` runs a Job and rolls pod by pod for compatible changes such as patch releases, and `Explicit` rolls while `spec.update.revision` stays the same. `RecreateUpdateUsed` reports what the last update did. The key facts to remember are these:

- Take a fresh dump before every upgrade.
- Restore next to the damaged database, then switch `spec.db.database`.
- A new Keycloak version changes the schema; going back needs the old image and the old database.
- An image that never started changed nothing; putting the old image back is enough.

<!-- astrona:playground:destroy -->
