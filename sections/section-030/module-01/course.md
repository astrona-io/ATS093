# Put Keycloak Behind A Reverse Proxy

A reverse proxy is a server that receives requests from clients and forwards them to a server behind it. In front of Keycloak it usually does three jobs: it ends the TLS connection, it decides which paths reach Keycloak at all, and it protects Keycloak from too many requests. Each job has a matching setting on the Keycloak side, and a mismatch between the two is where most edge problems come from.

This module builds that edge with nginx and checks every part of it from the outside. Keep one sentence in mind: **the proxy decides what the world can reach, and Keycloak must know what the world sees.** If the proxy ends TLS, Keycloak must know its public address is `https://`. If the proxy blocks the administration console, the administrators still need another way in.

The module has three parts. **TLS Termination Modes And Proxy Headers** explains edge termination, re-encrypt and passthrough, and sets the hostname and proxy headers. **What To Expose Through The Proxy** decides which paths nginx forwards; a graded lab follows it. **Brute Force Detection And Rate Limiting** adds lockout in the realm and a rate limit at nginx; a second graded lab follows it.

## Learning objectives

After this module you can:

- Explain edge termination, re-encrypt and passthrough, and the Keycloak settings each one needs.
- Set the public hostname, the internal administration URL and `proxy.headers` in a `Keycloak` resource.
- Configure nginx to forward only `/realms/`, `/resources/` and `/.well-known/`, and keep `/admin/` and `/realms/master/` internal.
- Explain why the management port `9000` and its `/metrics` and `/health` paths are never exposed.
- Turn on brute force detection in a realm and read a user's lockout state.
- Limit the request rate to the token endpoint with nginx `limit_req` and prove it with a burst of requests.

## Before you start

You need to know what TLS and a certificate are, what an HTTP header is, and how a `Keycloak` resource and a Kubernetes ConfigMap are changed with `kubectl`. You do not need to know nginx; each directive is explained where it is used.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance, already set up for the proxy: public hostname `https://keycloak.localtest.me:8443` |
| `nginx` | The reverse proxy. It ends TLS on port `8443` with a self-signed certificate in the Secret `edge-tls` and reads its configuration from the ConfigMap `nginx-conf` |
| `inventory` | The realm, with the users `alice` (password `alice-password`) and `bob` (password `bob-password`) and the public client `inventory-cli` |
| `postgres` | PostgreSQL 17, the database Keycloak uses |
| `tester` | A client pod with `curl` and `jq`. Every test request in this module is sent from here |

The name `keycloak.localtest.me` points at `127.0.0.1` in public DNS. Inside the cluster, the `tester` pod reaches nginx under that name with the `curl` option `--resolve`, which tells `curl` which IP address to use for a host name. The certificate is self-signed, so `curl` also needs `-k`. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
