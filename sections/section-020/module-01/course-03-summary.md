# Summary

Two Keycloak pods are one server only when they share their caches. The database keeps what must survive, and Infinispan keeps the pods in step.

## What you learned

Keycloak writes everything it must not lose to the database: realms, clients, roles, users with their password hashes, the realm keys and, since Keycloak 26, user sessions. The `db` block of the `Keycloak` resource points at the database and takes the credentials from a Secret, and the pool fields size the connection pool of each instance. Because sessions are in the database, a refresh token still works after every Keycloak pod has been deleted and started again. The pods still keep cached copies and short-lived data, such as sign-ins in progress and failed login counts, that never reach the database.

Infinispan holds three kinds of cache. Local caches (`realms`, `users`, `authorization`, `keys`, `crl`) are copies on each pod. The replicated `work` cache carries the messages that tell other pods to drop a stale copy. Distributed caches (`authenticationSessions`, `sessions`, `clientSessions`, `offlineSessions`, `offlineClientSessions`, `loginFailures`, `actionTokens`) are shared across the members. Production mode uses `cache=ispn`; `cache=local` gives every pod private caches and no cluster.

With the default `jdbc-ping` stack, each instance records its address in the database and finds the others there, then talks to them on port `7800`, with port `57800` for failure detection. The operator's network policy keeps those ports open only between the Keycloak pods. A cluster is proven by an `ISPN000094` view that lists every member and, more reliably, by `vendor_cluster_size` equal to the instance count on every pod. A token that works on both pods proves much less, because sessions and keys come from the database. The key facts to remember are these:

- Ready pods are not members: check `vendor_cluster_size` on each pod.
- `cache=local` in a multi-instance deployment splits it into separate servers.
- Leave the operator's network policy on; it already allows the pods to cluster.
- Sessions survive restarts because Keycloak 26 persists them in the database.

<!-- astrona:playground:destroy -->
