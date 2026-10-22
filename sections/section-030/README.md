# Section 030: Edge Security

Users and applications reach Keycloak from outside the cluster, and the piece in front of it decides what they can reach. A reverse proxy that forwards every path publishes the administration console and the master realm to the internet. A proxy that ends TLS without telling Keycloak leaves it building `http://` addresses into every token. And a sign-in endpoint with no limits invites anyone to guess passwords as fast as the network allows.

This section puts Keycloak behind an nginx reverse proxy that ends TLS, and then closes the gaps one by one: the hostname and proxy headers, the paths the proxy exposes, brute force detection in the realm, and a rate limit at the proxy.

## What you will learn

- The three TLS modes at a proxy (edge termination, re-encrypt and passthrough) and the Keycloak settings each one needs.
- Setting the public hostname, an internal administration URL and `proxy.headers` in the `Keycloak` resource.
- Which paths to expose through the proxy and which to keep internal, and why port `9000` is never exposed.
- Turning on brute force detection in a realm and reading a user's lockout state.
- Limiting the request rate to the token endpoint with nginx `limit_req`.

## The learning path

The section has one module. It has a landing page, three short parts, two graded labs, each right after the part it tests, and a summary. The landing page starts the module's playground: Keycloak behind nginx, with TLS ended at nginx.

### 1. Put Keycloak Behind A Reverse Proxy

1. TLS Termination Modes And Proxy Headers
2. What To Expose Through The Proxy, followed by the lab **Expose Keycloak Through An Edge Proxy**
3. Brute Force Detection And Rate Limiting, followed by the lab **Stop Password Guessing**
4. Summary

## Section capstone: Harden The Keycloak Edge

The capstone starts with a proxy that forwards everything, management port included, a Keycloak that does not know it sits behind a proxy, and a realm with no protection against password guessing. You close every gap and prove each one with a request through the proxy. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-093-capstone-030
```
