# Summary

Realms and clients can be created in several ways, and each way treats a second application of the same data differently. Knowing which way you use tells you whether a change will take effect.

## What you learned

A `KeycloakRealmImport` starts a Job that imports the realm once, with a rule that skips a realm that already exists. The status shows `Started`, `Done` and `HasErrors`, and the Job log has the cause of a failure. Editing the resource later or deleting it does not change or remove the realm.

A realm that exists is changed through the Admin REST API. `kcadm.sh` runs inside the Keycloak pod, signs in with the initial administrator and offers `get`, `create`, `update` and `delete`. The API addresses clients by UUID, so a client is looked up by `clientId` first. The partial import endpoint adds clients, users, groups and roles in bulk, and `ifResourceExists` chooses `SKIP`, `OVERWRITE` or `FAIL` for entries that exist.

The `KeycloakOIDCClient` and `KeycloakSAMLClient` resources describe a client declaratively in the API version `v2alpha1`. They need `keycloakCRName`, `realm` and `client`, and the first two cannot change. The operator keeps the client in line with the resource and reports in status conditions.

Placeholders keep secret values out of a realm definition and read them from a Secret. Drift is the gap between the definition and the live realm, and the import never closes it. The key facts to remember are these:

- An import creates once and never updates.
- Changes to a live realm go through the Admin REST API.
- Clients are addressed by UUID in the API.
- Secrets go in placeholders or `secretRef`, never in the resource.

<!-- astrona:playground:destroy -->
