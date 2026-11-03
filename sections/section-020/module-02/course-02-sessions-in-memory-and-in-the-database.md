# Sessions In Memory And In The Database

A session is the record that a user signed in. Keycloak 26 keeps that record in the database and uses the distributed caches only as a fast copy in front of it. This part explains what that means for memory, for restarts and for the options that change it.

## Persistent user sessions

With persistent user sessions, the default, every user session, client session, offline user session and offline client session is written to the database. The caches `sessions`, `clientSessions`, `offlineSessions` and `offlineClientSessions` are loaded on demand: a session is read from the database when it is first used and then kept in memory. A cached session can be served by any pod in the cluster without a database round trip, and each entry has one owner pod.

Three results follow:

- All pods can be restarted at once and no session is lost, because the database has them.
- The caches can be bounded. A session that is evicted from memory is read from the database the next time it is used.
- Memory use no longer grows with the number of active sessions, only with the number you allow in the caches. The default limit is 10,000 entries per node, which you change with `cache-embedded-sessions-max-count` and the matching options of the other three caches.

## Offline sessions

An offline session is behind an offline token, which a client asks for with the scope `offline_access`. It outlives the browser session, so a realm with many mobile apps can hold far more offline sessions than online ones. They are stored in the database too. Bound `offline-sessions` and `offline-client-sessions` when the number of devices is large.

## Switching session caching off

If you accept that every session read goes to the database, you can stop caching sessions in memory with a provider option:

```text
--spi-user-sessions--infinispan--use-caches=false
```

This is only available when persistent user sessions are on. It lowers the memory of each node, removes cache synchronisation traffic between the pods and limits the effect of a slow or stalling node. The price is database load: workloads with many token introspection or token exchange calls read sessions all the time. Measure before you switch it on, and watch the database connection pool.

## Volatile sessions, deprecated

You can turn persistent sessions off with `--features-disabled=persistent-user-sessions`. Sessions then live in memory only, are lost when all pods restart, and use memory in proportion to the active users. This mode is deprecated since Keycloak 26.8 and will be removed. If your configuration still disables the feature, remove that setting. In the volatile mode a maximum size for `sessions` and `clientSessions` is not supported.

## The stateless feature

The `stateless` feature goes further: Keycloak no longer caches user entity data, and login failures, authentication sessions and action tokens are written to the database as well. Realm and authorization data are still cached, and the `work` cache still invalidates them. The database becomes the source of truth for everything session related. If several independent Keycloak clusters share one database, they exchange invalidation messages through a database table, and each cluster needs a unique name in `--cache-embedded-cluster-name`. This is the base of the multi-cluster setup of the high availability guide. Treat the feature as a design decision for an architecture review, not as a tuning switch.

## Check the sessions in your playground

Sign `alice` in and read the token, then list the sessions of the realm in the console (Sessions) or with `kcadm.sh`. Then restart one pod and refresh the token with the same refresh token to see the persistence work:

```sh
kubectl -n keycloak delete pod keycloak-1
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
```

The refresh token keeps working, because the session is in PostgreSQL.

## Mission

The realm `inventory` is going to receive a very large user import, and the pods have a memory limit. In the graded lab you bound the user cache and the session cache with the options of this module and prove that the cluster of two stays together after the rolling update.

<!-- astrona:playground:renew -->
