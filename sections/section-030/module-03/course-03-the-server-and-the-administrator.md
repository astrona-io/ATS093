# The Server And The Administrator

The realm settings protect your users. The settings in this part protect the thing that runs the realms. An attacker who becomes administrator of the master realm owns every realm, so this is where hardening pays the most.

## The bootstrap administrator

The operator creates the Secret `keycloak-initial-admin` with a user name and a generated password so that you can sign in the first time. It is a bootstrap account, and Keycloak marks it as temporary. Treat it that way:

1. Sign in once and create a named administrator for each person, in the master realm or, better, in a dedicated administration realm.
2. Give each administrator a second factor.
3. Remove the bootstrap account, or at least rotate its password and keep the Secret out of reach.

Use the least privilege that works. Realm administrators get the realm-specific roles (`manage-users`, `view-clients`) rather than the realm-wide administrator role. Give automation a client with a service account and only the roles it needs, instead of a user's password.

## Turn off what you do not use

Keycloak ships features that are off, preview or deprecated. The options `features` and `features-disabled` choose which are active; they are build options, so a change rolls the pods. List the features your realms need, and disable the rest. Fewer features mean less code that can be attacked and fewer things to patch. Do the same for protocols: if no client uses SAML, no SAML client should exist.

Switch off HTTP where TLS ends at the server: `http-enabled` is `false` by default in production mode, and the operator needs it on only when a proxy ends TLS. Behind a proxy, HTTP is acceptable only on a network that nothing else can enter, which a network policy enforces.

## The management interface

Health and metrics are served on a separate port, `9000`, so they never share a listener with user traffic. Keep it that way: do not route the port through the proxy, and restrict it by network policy to the monitoring system. The operator creates a network policy for Keycloak by default; keep it on and add rules, instead of removing it.

## Limits

An unprotected server can be slowed down by a few clients. Bound what a client can do:

- `http-pool-max-threads` and `http-max-queued-requests` limit the work in flight. A request over the queue limit is refused quickly with a `503`, which is better than a queue that grows until the pod is killed.
- Resource limits on the container keep one pod from taking a whole node.
- Rate limiting at the proxy stops a single address from using all threads.

## Security headers

A realm sends response headers that tell the browser how to treat Keycloak pages. The realm setting `browserSecurityHeaders` holds them, including `xFrameOptions`, `contentSecurityPolicy` and `strictTransportSecurity`. The defaults are strict about framing: only the same origin may embed a sign-in page. Loosen them for one client at a time, with the exact origin, instead of allowing all. Add `Strict-Transport-Security` at the proxy if it is not set, so browsers stop trying HTTP.

## Secrets and the supply chain

Keep secrets in Secrets, not in the resource: use `secret` references for the database password and `placeholders` for realm imports. Pin the image by version, or by digest, so that a restart does not pull a different build, and update on a schedule: security fixes arrive in patch releases. Limit who can read the Secrets of the namespace, because the initial admin and the database password sit there.

## Try it

Look at what the operator already hardens, and what is yours to do:

```sh
kubectl -n keycloak get networkpolicy
kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n keycloak get statefulset keycloak -o jsonpath='{.spec.template.spec.containers[0].securityContext}{"\n"}'
```

Note that anyone who can read Secrets in this namespace can read the administrator password.
