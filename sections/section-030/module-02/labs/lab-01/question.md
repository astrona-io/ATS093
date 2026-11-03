# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Replacing the certificate of the edge proxy

## Scenario

Keycloak runs behind an nginx proxy in the namespace `keycloak`, and users reach it at `https://keycloak.localtest.me:8443`. The monitoring team reports two problems with the certificate that nginx presents: it is issued for the wrong name, and it expires in a few days. nginx reads the certificate from the Secret `edge-tls`.

## Your task

Replace the certificate so that:

1. It names `keycloak.localtest.me` as an alternative name (`subjectAltName`).
2. It is valid for at least 90 more days.
3. nginx presents the new certificate.

Use a self-signed certificate. The tester pod has `openssl` for creating it.

## Constraints

- Keep the Secret name `edge-tls` and the type `kubernetes.io/tls`. Do not change the nginx Deployment or its ConfigMap.
- Do not change the `Keycloak` resource.

## Done when

- The certificate that nginx presents has the alternative name `keycloak.localtest.me` and is valid for more than 90 days.
- The certificate nginx presents is the one in the Secret `edge-tls`.
- The issuer through nginx is still `https://keycloak.localtest.me:8443/realms/inventory`, and `alice` gets a token.
