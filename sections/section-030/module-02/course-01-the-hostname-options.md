# The Hostname Options

Keycloak builds absolute URLs all the time: the issuer in every token, the redirects of the sign-in, the links in emails, the endpoints in the discovery document. All of them start with the hostname. If Keycloak guesses the hostname from the request, an attacker who can set a request header can choose what goes into those URLs. The hostname options remove the guess.

## The frontend URL

The option `hostname` sets the public address. In production mode you must set it, or turn off the check with `hostname-strict=false`. In the `Keycloak` resource it is `spec.hostname.hostname`:

```yaml
spec:
  hostname:
    hostname: https://keycloak.localtest.me:8443
```

Give a full URL when the public address has a port, a scheme the proxy changes, or a path, because a bare host name cannot carry them. The port is validated only when it is present; otherwise the default of the scheme is assumed. If Keycloak is exposed under a path such as `/auth`, put the path into the URL and set `http-relative-path` to match.

When `hostname` is set, `hostname-strict` is ignored. The issuer of a realm is then always `https://keycloak.localtest.me:8443/realms/<realm>`, regardless of which Host header arrived. That is what you want, because a token's issuer must be the same for every client.

## The administration address

`hostname-admin` gives the administration console and its API a separate address, for example an internal one. In the playground it is `http://localhost:8080`, reachable only inside the pod. If you set it, `hostname` must be a full URL. The option moves where the console loads from, but it does not block the Administration REST API on the public address. To block it, deny the paths on the proxy.

## The backchannel

The frontchannel is what the browser uses. The backchannel is what servers use to talk to Keycloak: token requests, introspection, the JWKS endpoint. By default both are the same. With `hostname-backchannel-dynamic=true`, Keycloak builds backchannel URLs from the incoming request, so an application inside the cluster can use `http://keycloak-service:8080` while browsers use the public name. It needs `hostname` as a full URL, and it trusts the request headers, so only turn it on when the internal network is trusted.

## Fully dynamic hostnames

`hostname-strict=false` makes Keycloak trust `Host` and `X-Forwarded-Host`. Use it only when untrusted clients cannot reach Keycloak except through a proxy that overwrites those headers. Otherwise a forged header changes the URLs in a password reset email, which is a host header injection. Prefer a fixed `hostname`.

## Debug the result

Set `hostname-debug=true` to expose a page under `/realms/<realm>/hostname-debug` that prints the URLs Keycloak computed. Use it while you test a change and switch it off afterwards, because it shows internal configuration.

## Try it

Ask for the discovery document with a spoofed header and compare the issuer with the configured one:

```sh
proxy_curl /realms/inventory/.well-known/openid-configuration | jq -r .issuer
proxy_curl /realms/inventory/.well-known/openid-configuration -H "X-Forwarded-Host: evil.example.com" | jq -r .issuer
```

Both answers are `https://keycloak.localtest.me:8443/realms/inventory`. The fixed hostname is why.
