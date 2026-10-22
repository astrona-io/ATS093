# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Edge security

## Scenario

A penetration test of the Keycloak edge in the namespace `keycloak` came back with a long list. nginx ends TLS on port `8443` for `keycloak.localtest.me` (certificate in the Secret `edge-tls`, configuration in the ConfigMap `nginx-conf`), and Keycloak sits behind it. The testers reported that tokens name an internal address, that the administration console and Keycloak's metrics are public, and that they could guess passwords as fast as they liked.

From inside the cluster you reach nginx under the public name with `curl -k --resolve keycloak.localtest.me:8443:<nginx Service IP>`. The realm `inventory` holds `alice` (password `alice-password`) and the test user `bob` (password `bob-password`).

## Your task

In the namespace `keycloak`, close every finding:

1. Tokens and discovery documents must use the issuer `https://keycloak.localtest.me:8443/realms/inventory`, and Keycloak must read the `X-Forwarded-*` headers that nginx overwrites.
2. nginx may forward only `/realms/`, `/resources/` and `/.well-known/`. `/admin/`, `/realms/master/`, `/metrics` and `/health` must answer `403` or `404` through nginx. Administrators reach the console at `http://localhost:8080` through a port-forward.
3. Lock a user out temporarily after five failed logins in `inventory`.
4. Answer a burst of requests to the token endpoint with `429` at nginx.

## Constraints

- Keep edge termination: nginx ends TLS, Keycloak keeps HTTP on port `8080`.
- Temporary lockout only, and rate limit the token endpoint only.
- Change the `Keycloak` resource, the ConfigMap `nginx-conf` and the realm settings. Do not change the certificate or the StatefulSet.
- `alice` must still get a token through nginx at a normal pace.

## Done when

- The issuer through nginx is the public `https://` address, and a token for `alice` through nginx carries it.
- `spec.proxy.headers` is `xforwarded`, and nginx sets `X-Forwarded-Proto` and `X-Forwarded-Host`.
- The four internal paths answer `403` or `404` through nginx.
- `bruteForceProtected` is `true`, `failureFactor` `5`, `permanentLockout` `false`, and six wrong passwords lock `bob` out.
- A burst of 30 requests to the token endpoint through nginx gets at least one `429`.
