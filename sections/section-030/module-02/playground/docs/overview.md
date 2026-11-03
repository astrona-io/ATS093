# Overview: Certificates, Hostname And Mutual TLS (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys Keycloak behind an nginx reverse proxy that ends TLS, and imports one realm, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance; public hostname `https://keycloak.localtest.me:8443`, administration console at `http://localhost:8080`, `proxy.headers: xforwarded`, HTTP on |
  | `nginx` | Ends TLS on port `8443` with the self-signed certificate in the Secret `edge-tls` (name `keycloak.localtest.me`); configuration in the ConfigMap `nginx-conf` |
  | `inventory` | The realm, with the users `alice` (password `alice-password`) and `bob` and the public client `inventory-cli` |
  | `postgres` | PostgreSQL 17, the database Keycloak uses |
  | `tester` | Client pod with `curl`, `jq` and `openssl` |

## Helpers

Paste these once in each new terminal. `proxy_curl` requests a path through nginx under the public name. `served_cert` runs `openssl x509` on the certificate that nginx presents, with the options you pass.

```sh
proxy_curl() {
  NGINX_IP=$(kubectl -n keycloak get service nginx -o jsonpath='{.spec.clusterIP}')
  kubectl -n keycloak exec deploy/tester -- curl -sk \
    --resolve "keycloak.localtest.me:8443:$NGINX_IP" "${@:2}" "https://keycloak.localtest.me:8443$1"
}
served_cert() {
  kubectl -n keycloak exec deploy/tester -- sh -c \
    "echo | openssl s_client -connect nginx:8443 -servername keycloak.localtest.me 2>/dev/null | openssl x509 -noout $1"
}
```

Use them like this: `proxy_curl /realms/inventory/.well-known/openid-configuration | jq -r .issuer` and `served_cert "-subject -dates -ext subjectAltName"`.

## Practice tasks

- Read the subject, the dates and the alternative names of the certificate nginx presents with `served_cert`.
- Request the discovery document with `--resolve` and a different `Host` name, for example `-H "X-Forwarded-Host: evil.example.com"`, and check which issuer Keycloak returns. Compare it with `hostname-strict`.
- Create a second certificate in the tester pod with `openssl req -x509`, replace the Secret `edge-tls`, restart nginx and watch `served_cert` change.
- Add `ssl_verify_client optional;` and `ssl_client_certificate` to the nginx configuration and look at `$ssl_client_verify`.
- Print the options the operator passes with `kubectl -n keycloak get statefulset keycloak -o yaml | grep -i hostname`.
