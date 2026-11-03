# Summary

Caches are a trade between memory and database reads. Keycloak sets sensible defaults and lets you move them with options.

## What you learned

The local caches `realms`, `users`, `authorization` and `keys` hold copies of database data on each pod, with a default of 10,000 entries and 1,000 for keys. The distributed caches hold sessions, authentication sessions and action tokens, and the replicated `work` cache carries invalidation messages. The option `cache-embedded-<name>-max-count` bounds a cache by entry count and per node. It does not exist for `authenticationSessions`, `actionTokens`, `loginFailures` and `work`. Custom XML cache files are possible, but only the `cache-` options are supported.

Persistent user sessions are the default, so sessions are in the database and the caches are an on-demand copy that can be bounded. Disabling session caching with the `use-caches` provider option lowers memory and traffic at the cost of database load. The volatile mode is deprecated, and the stateless feature moves more state into the database.

The default `jdbc-ping` stack finds pods through the database, and TCP stacks are encrypted with mutual TLS using a generated certificate that rotates. A service mesh can break that exchange. Owner copies spread across machines when the operator sets the machine name and pods are on different nodes. The key facts to remember are these:

- A max count limits entries per node, not bytes.
- Sessions in the database survive a restart; memory only holds a copy.
- Keep `jdbc-ping` and the default encryption on Kubernetes.
- Change cache options one at a time and check `vendor_cluster_size` after the rollout.

<!-- astrona:playground:destroy -->
