# The Ways To Export And Import

Keycloak offers three routes for getting a realm out of one place and into another. They overlap, but each one was made for a different job, and picking the wrong one is how a migration ends with a realm that has no users or no secrets.

## The partial export

The partial export is part of the Administration console (Realm settings, Action, Partial export) and of the Administration REST API. It runs on a live server and returns one JSON document.

```sh
curl -s -X POST -H "Authorization: Bearer $T" \
  'http://keycloak-service:8080/admin/realms/inventory/partial-export?exportClients=true&exportGroupsAndRoles=true'
```

You choose whether to include clients, and whether to include groups and roles. You cannot include users. Secret values, such as client secrets, come back as a mask of asterisks instead of the real value. The partial export is the tool for sharing the shape of a realm: its settings, clients, roles and groups.

## The offline export and import

The `kc.sh export` and `kc.sh import` commands read and write the whole realm, including users. They run as their own process against the database, not inside the running server, so they are used on a stopped server or with a separate process. Options include:

| Option | What it does |
| --- | --- |
| `--realm` | Export one realm; without it, every realm |
| `--dir` or `--file` | Write to a directory, or to one file |
| `--users` | How users are written: `skip`, `realm_file`, `same_file`, or `different_files` (the default) |
| `--users-per-file` | The size of each users file when they are split |

The matching `kc.sh import --dir` or `--file` reads them back. With `--override true`, which is the default, an existing realm is replaced; with `false` it is skipped. This is the route that carries users and their credentials, so it is the one for moving a whole realm with its people. The price is that it is an operation on a process, not on a running pod. In a cluster you need a Job or a temporary pod with the same image, the same database settings and a volume for the files.

## The realm import at start

The server can import realm files when it starts: put them in `data/import` and start with `--import-realm`. A realm that already exists is skipped, so starting again does not overwrite changes made since. The operator wraps this in the `KeycloakRealmImport` resource. It holds the realm as an embedded JSON-shaped document, starts a Job, and imports the realm when the Job runs.

```yaml
apiVersion: k8s.keycloak.org/v2beta1
kind: KeycloakRealmImport
metadata:
  name: inventory
spec:
  keycloakCRName: keycloak
  placeholders:
    ALICE_PASSWORD:
      secret:
        name: inventory-secrets
        key: alice-password
  realm:
    realm: inventory
    enabled: true
```

The placeholders turn `${ALICE_PASSWORD}` inside the realm into a value read from a Secret when the Job runs, so the secret does not sit in the resource. The import happens once: it creates a realm that does not exist and does not change one that does.

## Choosing

| You need | Use |
| --- | --- |
| The shape of a realm for review or reuse | Partial export |
| A realm with its users, moved between servers | Offline export and import |
| A new environment created from a file in Git | `KeycloakRealmImport` |
| A copy of everything, including sessions and keys | A database backup, not an export |

The last row matters. An export is for configuration. If you want to get back everything after a loss, take a dump of the database.
