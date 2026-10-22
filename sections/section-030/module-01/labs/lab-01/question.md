# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Edge security

## Scenario

The network team put nginx in front of Keycloak in the namespace `keycloak`. nginx ends TLS on port `8443` for the public name `keycloak.localtest.me`, with the certificate in the Secret `edge-tls`, and reads its configuration from the ConfigMap `nginx-conf`. Sign-ins through the proxy look broken to the application team, and a security review found the administration console on the public address.

From inside the cluster you reach nginx under the public name with `curl -k --resolve keycloak.localtest.me:8443:<nginx Service IP>`.

## Your task

In the namespace `keycloak`:

1. Make Keycloak build its public address: every token and discovery document must use the issuer `https://keycloak.localtest.me:8443/realms/inventory`.
2. Make Keycloak read the `X-Forwarded-*` headers, and make nginx overwrite `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Forwarded-Host` and `X-Forwarded-Port` on every request it forwards.
3. Make nginx forward only `/realms/`, `/resources/` and `/.well-known/`. The administration console (`/admin/`), the master realm (`/realms/master/`) and the management endpoints (`/metrics`, `/health`) must answer `403` or `404` through nginx.
4. Keep a way in for administrators: set the administration console's address to `http://localhost:8080`, reached through a port-forward to `keycloak-service`.

## Constraints

- Keep edge termination: nginx ends TLS, and Keycloak keeps HTTP on port `8080`.
- Change the `Keycloak` resource and the ConfigMap `nginx-conf`. Do not change the certificate, the nginx Deployment's volumes or the StatefulSet.
- `alice` (password `alice-password`) must still get a token through nginx from the client `inventory-cli`.

## Done when

- The discovery document of `inventory` through nginx names the issuer `https://keycloak.localtest.me:8443/realms/inventory`.
- `spec.proxy.headers` is `xforwarded`, and the nginx configuration sets `X-Forwarded-Proto` and `X-Forwarded-Host`.
- `/admin/master/console/`, `/realms/master/.well-known/openid-configuration`, `/metrics` and `/health/ready` answer `403` or `404` through nginx.
- A token for `alice` requested through nginx carries the public issuer.
