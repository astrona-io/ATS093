# Summary

The proxy in front of Keycloak decides what the outside world can reach, and Keycloak must know what the outside world sees. An edge is secure when both sides agree.

## What you learned

A proxy handles TLS in one of three ways. With edge termination it ends TLS and sends plain HTTP to Keycloak, which needs `http-enabled` and `proxy-headers`. With re-encrypt it opens a new TLS connection to Keycloak, which needs `proxy-headers` and a certificate. With passthrough it forwards TLS untouched, which needs `proxy-protocol-enabled` and must not use `proxy-headers`. In a `Keycloak` resource, `hostname.hostname` sets the public address Keycloak writes into every token and redirect, `hostname.admin` gives the administration console its own internal address, and `proxy.headers` (`xforwarded` or `forwarded`) makes Keycloak read the headers the proxy overwrites on each request.

An edge proxy forwards only `/realms/`, `/resources/` and `/.well-known/`. It answers `/admin/` and `/realms/master/` itself, and it never forwards the management port `9000` with its `/metrics` and `/health` endpoints. Administrators reach the console on an internal address. The proof is one request per path from the outside, reading only the status code. nginx reads its configuration at start, so every change to its ConfigMap needs a restart.

Brute force detection is a realm setting: `bruteForceProtected`, `failureFactor`, and `permanentLockout` with its wait times. A locked user gets the same `401` as a wrong password, and the lockout state is visible under `attack-detection` in the Admin REST API, where an administrator can also end it. A rate limit at the proxy, with nginx `limit_req_zone` and `limit_req` on the token endpoint and `limit_req_status 429`, protects the server from floods that brute force detection cannot see. The key facts to remember are these:

- A full URL as the hostname makes every token carry the public issuer, whichever way the request came in.
- `proxy-headers` and passthrough never go together.
- Block `/admin/` and `/realms/master/` at the proxy, and never proxy port `9000`.
- Brute force detection protects each user; the proxy's rate limit protects the server.

<!-- astrona:playground:destroy -->
