# Solution: Recover After A Failed Upgrade

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks six things: the image and a ready pod, the update strategy, the restored database, the kept original, the realm `restore-check`, and a token for `alice`.

## Step 1: Why does no pod run?

```sh
kubectl -n keycloak get keycloak keycloak \
  -o go-template='{{range .status.conditions}}{{.type}}={{.status}} {{.message}}{{"\n"}}{{end}}'
kubectl -n keycloak get pods
kubectl -n keycloak describe pod keycloak-0 | tail -8
```

`keycloak-0` shows `ErrImagePull` or `ImagePullBackOff`, and its events say the image `quay.io/keycloak/keycloak:26.8.99` cannot be pulled. That tag does not exist. Read the resource:

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.image} {.spec.update}{"\n"}'
```

`spec.image` names the missing tag, and there is no `update` block, so the strategy is the default `RecreateOnImageChange`. On the image change the operator stopped the running pod first, and then the new one could not start: downtime with no way forward.

## Step 2: Decide whether the database needs the restore for the upgrade

The new image never started, so it never touched the database schema. Putting the old image back is enough for the upgrade itself. The restore is still needed, but for a different reason: the realm deleted after the dump.

## Step 3: Roll back the image and set the strategy

Remove the override, so the operator uses its own default image again, and set `Auto`:

```sh
kubectl -n keycloak patch keycloak keycloak --type json -p '[{"op":"remove","path":"/spec/image"}]'
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{"update":{"strategy":"Auto"}}}'
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.spec.containers[0].image}{"\n"}'
```

The pod runs `quay.io/keycloak/keycloak:26.8.1` and the resource is ready. Setting `spec.image` to `quay.io/keycloak/keycloak:26.8.1` explicitly works too, but then a later operator upgrade would keep running 26.8.1.

## Step 4: Restore the realm from the dump

Restore into a new database, next to the damaged one, and switch Keycloak to it:

```sh
kubectl -n keycloak exec deploy/postgres -- createdb -U keycloak keycloak_restored
kubectl -n keycloak exec deploy/postgres -- pg_restore -U keycloak -d keycloak_restored --no-owner /backup/keycloak.dump
kubectl -n keycloak patch keycloak keycloak --type merge -p '{"spec":{"db":{"database":"keycloak_restored"}}}'
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

## Step 5: Prove it

```sh
kubectl -n keycloak exec deploy/tester -- \
  curl -s -o /dev/null -w '%{http_code}\n' http://keycloak-service:8080/realms/restore-check/.well-known/openid-configuration
kubectl -n keycloak exec deploy/tester -- \
  curl -s http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli \
    -d username=alice -d password=alice-password | jq -r 'has("access_token")'
```

The realm answers `200`, and the token request answers `true`. The token request uses the password grant, which OAuth 2.1 drops; it is used here only to test from a terminal.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix the tag to a version that exists, such as a newer release | The new version changes the schema; if it fails, the way back needs the dump. The task asks for 26.8.1 |
| Restore over `keycloak` | The record of what changed after the dump is lost. The task forbids it |
| Leave the strategy at the default | The next image change stops every pod again |
| Reinstall the operator | It changes nothing about the resource's `spec.image` |

## Common mistakes

- Restoring before the image is fixed. Keycloak cannot start to read the restored database until it has an image it can pull.
- Forgetting that `Auto` rolls pod by pod only for compatible changes. A minor or major upgrade still restarts every pod.
- Checking before the second rollout is complete.
