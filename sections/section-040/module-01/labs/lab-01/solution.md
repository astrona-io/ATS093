# Solution: Restore Keycloak From A Database Dump

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the resource uses `keycloak_restored` and is ready, the damaged database still exists, the realm `restore-check` answers, and `alice` gets a token.

## Step 1: Confirm the loss and the dump

Check what the live database holds, and that the dump is where the task says:

```sh
kubectl -n keycloak exec deploy/postgres -- psql -U keycloak -d keycloak -c 'select name from realm;'
kubectl -n keycloak exec deploy/postgres -- ls -l /backup
```

The live database lists `master` and `inventory`, without `restore-check`. The file `keycloak.dump` is there. Before you rely on a dump, list its contents; `pg_restore --list` reads the archive without restoring anything:

```sh
kubectl -n keycloak exec deploy/postgres -- pg_restore --list /backup/keycloak.dump | head -15
```

The list shows the archive's header and the first tables, so the file is a valid custom-format dump.

## Step 2: Restore into a new database

Create the new database and load the dump into it. `--no-owner` makes the restored tables belong to the user running the restore:

```sh
kubectl -n keycloak exec deploy/postgres -- createdb -U keycloak keycloak_restored
kubectl -n keycloak exec deploy/postgres -- pg_restore -U keycloak -d keycloak_restored --no-owner /backup/keycloak.dump
kubectl -n keycloak exec deploy/postgres -- psql -U keycloak -d keycloak_restored -c 'select name from realm;'
```

The restored database lists `restore-check` again. The damaged database `keycloak` is untouched.

## Step 3: Switch Keycloak to the restored database

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{"db":{"database":"keycloak_restored"}}}'
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

The operator replaces the pod, and the new pod reads the restored database. Wait for the rollout; a pod that still runs against the old database answers with the old data.

## Step 4: Prove the restore

Ask for the realm `restore-check` and for a token for `alice`. The token request uses the password grant, which OAuth 2.1 drops; it is used here only to test from a terminal:

```sh
kubectl -n keycloak exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' http://keycloak-service:8080/realms/restore-check/.well-known/openid-configuration
kubectl -n keycloak exec deploy/tester -- \
  curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password | jq -r 'has("access_token")'
```

The realm answers `200`, and the token request answers `true`.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `dropdb keycloak`, then restore under the same name | It works, and the only record of what changed after the dump is gone. The task forbids it |
| Restore into `keycloak` over the existing tables | `pg_restore` fails on objects that exist, or mixes old and new rows |
| Create `restore-check` and `alice` again by hand | They get new IDs, `alice` gets a new password hash, and anything linked to the old IDs breaks |
| Edit the StatefulSet's database variable | The operator puts it back on its next reconciliation |

## Common mistakes

- Forgetting `--no-owner` when the dump was taken by a different user than the one restoring.
- Checking before the rollout is complete.
- Forgetting that `kcadm.sh` must sign in again after the pods restart.
