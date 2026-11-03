# Certificates, Hostname And Mutual TLS

An edge proxy that ends TLS makes three promises. The name in the address bar is the name Keycloak writes into every URL, the certificate that proves it is valid and will be replaced before it expires, and the connections that carry secrets are encrypted and authenticated on both sides. A break in any one of them looks the same to a user: a browser warning, a redirect to the wrong host, or a client that cannot validate a token.

This module follows a name from the address bar to the certificate. Keep one sentence in mind: **the hostname decides what Keycloak writes, the certificate decides what a client believes, and the proxy decides which headers the server trusts.**

The module has four parts. **The Hostname Options** covers `hostname`, `hostname-admin`, `hostname-strict` and the backchannel. **Certificates And Trust** covers the certificate on the proxy or on Keycloak, the truststore and rotation; a graded lab follows it. **Mutual TLS And Client Certificates** covers `https-client-auth`, the X.509 lookup behind a proxy and certificate bound tokens. **Diagnosing TLS And Hostname Problems** gives the order in which to check a failure.

## Learning objectives

After this module you can:

- Explain what `hostname`, `hostname-admin`, `hostname-backchannel-dynamic` and `hostname-strict` change.
- Read a certificate with `openssl` and check its names and expiry.
- Replace a TLS Secret and make the workload that uses it load the new certificate.
- Configure Keycloak to trust additional certificate authorities with `spec.truststores`.
- Explain what mutual TLS adds, and why a client certificate in a proxy header is security sensitive.
- Work through a hostname or certificate failure in a fixed order.

## Before you start

You need the module Put Keycloak Behind A Reverse Proxy: edge TLS termination, `proxy.headers` and what to expose. You should know what a certificate, a CA and a subject alternative name are.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance, public hostname `https://keycloak.localtest.me:8443`, HTTP inside the cluster |
| `nginx` | The edge proxy; ends TLS with the Secret `edge-tls` |
| `inventory` | The realm, with the users `alice` and `bob` and the public client `inventory-cli` |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl`, `jq` and `openssl` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
