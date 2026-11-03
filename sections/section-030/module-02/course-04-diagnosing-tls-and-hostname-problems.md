# Diagnosing TLS And Hostname Problems

TLS and hostname failures present as three different symptoms, and each points at a layer. Check the layers in order, from the network upward, and stop at the first fault.

## The order of checks

1. **Can the client reach the port?** `curl -v` shows whether the connection opens. A refused connection is a Service, a port or a network policy problem.
2. **Does the handshake complete?** `openssl s_client -connect host:port -servername name` shows the certificate chain and the verification result. A failure here is the certificate: expired, wrong name, missing intermediate, or an authority the client does not trust.
3. **Does the proxy forward the request?** A `502` or `504` is the proxy failing to reach Keycloak. A `403` or `404` is a proxy rule.
4. **Does Keycloak build the right URLs?** Compare the issuer and the redirect URL with the public name. Wrong host or scheme points at `hostname` or `proxy.headers`.
5. **Does the client trust what it receives?** A token whose issuer differs from the one the application expects is rejected by the application, not by Keycloak.

## Symptoms and likely causes

| Symptom | Likely cause |
| --- | --- |
| Browser shows a name mismatch | The certificate lacks the name in its subject alternative names |
| Browser shows an expired certificate | Not replaced in time, or replaced but the proxy was not restarted |
| Redirect to `http://` after sign-in | `proxy.headers` missing or the proxy does not send `X-Forwarded-Proto` |
| Redirect to an internal host name | `hostname` not set or `hostname-strict=false` with a wrong `Host` header |
| Application says invalid issuer | The application used the backchannel URL and got a different issuer |
| `PKIX path building failed` in the Keycloak log | Keycloak does not trust the other server's certificate authority |
| `JGRP000006` between pods | The cluster transport is blocked by a mesh |

## Tools

```sh
served_cert "-subject -issuer -dates -ext subjectAltName"
proxy_curl /realms/inventory/.well-known/openid-configuration | jq '{issuer, authorization_endpoint, token_endpoint}'
kubectl -n keycloak logs keycloak-0 | grep -i -E "PKIX|certificate|hostname" | tail
```

Use `hostname-debug` only on a test system, and set `log-level` to `debug` for the category you need, not for the whole server.

## Habits that prevent outages

- Monitor the days left of every certificate and alert at 30 and at 7 days.
- Keep the certificate names in version control, not only the certificates.
- Test a rotation in a staging system, including the restart.
- After every change, ask the system what it serves, not what you stored.
