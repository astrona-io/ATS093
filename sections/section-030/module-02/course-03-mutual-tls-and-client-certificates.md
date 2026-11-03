# Mutual TLS And Client Certificates

In ordinary TLS only the server proves who it is. In mutual TLS the client also presents a certificate, and the server decides whether to accept it. Keycloak uses this for two things: authenticating users or clients with an X.509 certificate, and binding tokens to the certificate that asked for them.

## Asking Keycloak for client certificates

When Keycloak ends TLS itself, the option `https-client-auth` sets what it does with a client certificate:

| Value | Behaviour |
| --- | --- |
| `none` | The client is not asked for a certificate (default) |
| `request` | Keycloak asks; a client without a certificate is still accepted |
| `required` | A connection without a valid certificate is refused |

The truststore decides which certificate authorities are accepted. Use `request` when only some clients use certificates, because `required` blocks browsers that do not have one. Keep in mind that `request` applies to the whole listener; the sign-in flow then decides whether to use the certificate, through the X.509 authenticator in the authentication flow of the realm.

## Behind a proxy

With edge or re-encrypt termination, the proxy sees the certificate, and Keycloak sees only a connection from the proxy. The proxy must pass the certificate in a request header, and Keycloak must be told which header and which proxy flavour. Choose a lookup provider at build time, for example `spi-x509cert-lookup--provider=nginx`, and name the header with `spi-x509cert-lookup--<provider>--ssl-client-cert`. Supported flavours include apache, haproxy, nginx, traefik, envoy and RFC 9440 proxies.

This is security sensitive. A header is just text, and if a client can send it, the client can claim any certificate. The rules:

- The proxy must overwrite the header on every request, so a value sent by the client never reaches Keycloak.
- Keycloak must accept connections only from the proxy. Use `proxy-trusted-addresses` and a network policy.
- Enable `trust-proxy-verification` only if the proxy verifies the whole certificate chain. Enabled without verification, it lets a forged certificate sign in.
- Where you can, prefer TLS passthrough, because then no header is needed.

A sketch of the nginx side shows the intent: the proxy verifies the client certificate and then sets one header from the verified value.

```nginx
ssl_client_certificate /etc/nginx/tls/client-ca.crt;
ssl_verify_client optional;
proxy_set_header SSL_CLIENT_CERT $ssl_client_escaped_cert;
```

## Certificate bound tokens

OAuth 2.0 mutual TLS can bind an access token to the client certificate that requested it. A resource server then checks that the caller presents the same certificate, so a stolen token is useless on its own. In the client settings this is the option for certificate bound access tokens, and it needs the client to authenticate with a certificate. It adds protection against token theft at the price of running mutual TLS between every client and Keycloak.

## When to use it

Use mutual TLS where you control both sides and a leaked secret is costly: service-to-service calls of a platform, high-risk administrative clients, regulated environments. For ordinary web users, passwords with a second factor or passkeys are easier to run than client certificates. For clients, a signed JWT or a secret in a Secret object is simpler, and mutual TLS is the next step when that is not enough.

## Try it

In the playground, read how the proxy would receive a certificate. Print the nginx configuration and find the lines that a client certificate would need:

```sh
kubectl -n keycloak get configmap nginx-conf -o jsonpath='{.data.keycloak\.conf}'
```

There are none yet. Add `ssl_verify_client optional;` and a `ssl_client_certificate` line, restart nginx and send a request with `curl --cert`; then remove the change.
