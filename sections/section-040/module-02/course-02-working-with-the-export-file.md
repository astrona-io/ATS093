# Working With The Export File

An export file is easy to produce and easy to misuse. It is JSON that looks like a complete realm, and it is not. This part looks at what is inside, what is hidden, and how to turn it into a file that you are willing to commit.

## What a partial export holds

The top of the file has the realm settings: name, token lifespans, password policy, events, themes, flows and required actions. Below that come the lists you asked for: `clients`, `groups`, and `roles` with a `realm` list and a `client` map. A realm with `inventory-cli` and `inventory-api` gives one entry for each client, with its redirect URIs, flow switches, mappers and scopes.

Two things are not there:

- **Users.** A partial export has no `users` list, however you call it. A realm moved this way arrives with no people. Use the offline export, with `--users`, when the users must come along.
- **Secrets.** Every secret value is replaced with ten asterisks: `"secret": "**********"`. Importing that file would create a client whose secret is literally ten asterisks.

## Ids and the file

The export includes the ids of the realm and of the objects inside it. That is why an import into a server that already holds the same ids can fail, and why importing a copy of a realm next to the original needs care. For a realm that is recreated after a loss, or built in a clean environment, the ids do no harm and keep references stable.

## Make it safe to keep

A file in version control must hold no secret. Replace each masked value with a placeholder, and let the import fill it from a Secret:

```sh
jq '(.clients[] | select(.clientId=="inventory-api") | .secret) = "${API_SECRET}"' \
  inventory-export.json > inventory-realm.json
```

In a `KeycloakRealmImport`, declare `API_SECRET` under `placeholders` and point it at a Secret key. Do the same for user passwords if you import users. Then check the file: search it for the asterisks and for any real value you know.

```sh
grep -c '\*\*\*\*\*\*\*\*\*\*' inventory-realm.json
```

The count must be `0`. A mask left behind is a secret that will be wrong after the import; a real value left behind is a leak.

## Review the diff

The value of a file in Git is the diff. Sort the keys so that two exports compare cleanly (`jq -S .`), and remove noise that changes on every export, if your tooling needs it. A diff between yesterday's export and today's shows who changed what, which makes the file a record of drift.

## Mission

The realm `inventory` has a confidential client with a secret, a role and a group. In the graded lab you take a partial export through the Administration REST API, save it in the `tester` pod, and replace the masked secret with the placeholder, so that the file could be kept in version control.

<!-- astrona:playground:renew -->
