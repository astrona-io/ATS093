# Summary

An export describes a realm; it does not copy it. Choose the route for the job and know what each one leaves out.

## What you learned

The partial export runs on a live server and returns clients, groups and roles, but never users, and it masks every secret. The offline export and import carry users, but run as their own process against the database. The `KeycloakRealmImport` creates a realm once from a file, fills placeholders from Secrets, and never updates a realm that exists.

A file for version control must hold no secrets: replace each mask with a placeholder and check that no asterisks or real values remain. Environments differ in hostnames, secrets, users and keys; keep the structure in one template and the values per environment. Pick, and write down, how changes reach a live realm after the first import.

An upgrade is planned from the upgrading guide, rehearsed on a restored copy, and carried out with a fresh dump in hand. The key facts to remember are these:

- A partial export has no users and masks secrets.
- An import creates a realm and does not update one.
- A file is safe to keep only after the masks are replaced by placeholders.
- The rehearsal on a copy tells you the length of the window.

<!-- astrona:playground:destroy -->
