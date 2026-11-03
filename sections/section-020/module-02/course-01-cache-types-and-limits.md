# Cache Types And Limits

Keycloak creates its caches itself and gives each one a default. You rarely write cache configuration. You choose how big each cache may grow, and that choice is made with a command-line option, not with a file.

## The local caches

A local cache lives on one pod and holds a copy of data from the database, so the pod can answer without asking PostgreSQL. Four groups of data are cached this way:

| Cache | What it holds | Default limit |
| --- | --- | --- |
| `realms` | Realms and what belongs to them: clients, roles, groups | 10,000 entries |
| `users` | Users and their role grants and group memberships | 10,000 entries |
| `authorization` | Resources, permissions and policies of authorization services | 10,000 entries |
| `keys` | Public keys of clients and identity providers | 1,000 entries, and an entry expires after one hour |

The keys expire on purpose: a key that a client has rotated must be fetched again within an hour. The other local caches keep an entry until the limit forces it out or another pod tells this pod that the data changed.

## The distributed caches

A distributed cache holds data that exists nowhere else, so each entry has an owner pod and is reachable from the other pods. The caches are:

| Cache | What it holds |
| --- | --- |
| `authenticationSessions` | A sign-in that is in progress, until it ends or expires |
| `sessions`, `clientSessions` | Online user sessions and client sessions |
| `offlineSessions`, `offlineClientSessions` | Sessions behind offline tokens |
| `loginFailures` | Failed login counters, when the deprecated mode that keeps them in memory is on |
| `actionTokens` | Metadata of tokens used once, such as the link in a reset password mail |

The login failure data of brute force detection is written to the database by default. The in-memory `loginFailures` cache is a fallback of a deprecated feature. A multi-site deployment keeps the counters in an external Infinispan.

The only replicated cache is `work`. It carries the short messages that tell the other pods to drop an out-of-date copy, so you should not expect it to grow.

## Bounding a cache

The option has a fixed shape. Take the cache name in lower case with dashes between words and put it in the middle:

```text
--cache-embedded-<cache-name>-max-count=<number>
```

The names that exist are `realms`, `users`, `authorization`, `keys`, `crl`, `sessions`, `client-sessions`, `offline-sessions` and `offline-client-sessions`. As an environment variable the same option reads `KC_CACHE_EMBEDDED_USERS_MAX_COUNT`. In a `Keycloak` resource you write it as an entry of `additionalOptions`:

```yaml
spec:
  additionalOptions:
    - name: cache-embedded-users-max-count
      value: "2000"
```

Three caches cannot be bounded at all: `authenticationSessions`, `actionTokens` and `work`, and `loginFailures` as well. They hold short-lived data. When a cache reaches its limit, Infinispan evicts entries, and the next request for an evicted entry reads the database again. A limit therefore never loses data in the local caches; it only costs a query.

## What a limit does not do

A max count counts entries, not bytes. One realm entry with thousands of clients is far larger than a user entry, so a limit of 10,000 on `realms` is not the same memory as 10,000 on `users`. A limit also applies per node. Two pods with `users` limited to 2,000 can together hold up to 4,000 user entries, because every pod has its own copy of the local cache.

Try it in your playground. Print the current options and the cache related environment of a pod, then compare with the table:

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.additionalOptions}{"\n"}'
kubectl -n keycloak exec keycloak-0 -- printenv | grep -i cache || echo "no cache options set"
```

No cache options are set, so every cache runs with the defaults above.

## Your own cache file

Keycloak can read a cache configuration file with `--cache-config-file`, and the default is `conf/cache-ispn.xml`. Overriding the defaults in XML is technically possible but not supported. The supported way to change a default is a `cache-...` option. If you do change a cache in XML, add `cache-config-mutate=true` to silence the warning that a modified default was detected. Treat a custom file as a last resort and keep it in version control.
