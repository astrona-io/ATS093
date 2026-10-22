# Overview: Put Keycloak Behind A Reverse Proxy (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the Keycloak Operator, deploys Keycloak behind an nginx reverse proxy that ends TLS, and imports one realm, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- The **Keycloak Operator 26.8.1** in the namespace **`keycloak`**, and everything else in the same namespace:

  | Name | What it is |
  | --- | --- |
  | `keycloak` (`Keycloak` resource) | One instance; public hostname `https://keycloak.localtest.me:8443`, administration console at `http://localhost:8080`, `proxy.headers: xforwarded`, HTTP on |
  | `nginx` | Ends TLS on port `8443` with the self-signed certificate in the Secret `edge-tls`; configuration in the ConfigMap `nginx-conf`. It forwards `/realms/`, `/resources/` and `/.well-known/`, and answers `/admin/` and `/realms/master/` with `403` |
  | `inventory` | The realm, with the users `alice` (password `alice-password`) and `bob` (password `bob-password`) and the public client `inventory-cli`. Brute force detection is **off** |
  | `postgres` | PostgreSQL 17, the database Keycloak uses |
  | `tester` | Client pod with `curl`, `jq` and `openssl` |

## Helpers

Paste these once in each new terminal. `proxy_curl` requests a path through nginx under the public name, with any extra `curl` options after the path. `status_of` prints only the HTTP status code of a path through the proxy. `kcadm` and `kcadm_login` run the administration tool in `keycloak-0` with the initial admin Secret.

```sh
proxy_curl() {
  NGINX_IP=$(kubectl -n keycloak get service nginx -o jsonpath='{.spec.clusterIP}')
  kubectl -n keycloak exec deploy/tester -- curl -sk \
    --resolve "keycloak.localtest.me:8443:$NGINX_IP" "${@:2}" "https://keycloak.localtest.me:8443$1"
}
status_of() {
  echo "$1 $(proxy_curl "$1" -o /dev/null -w '%{http_code}')"
}
kcadm() {
  kubectl -n keycloak exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm_login() {
  kcadm config credentials --server http://localhost:8080 --realm master \
    --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
    --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
}
```

Use them like this: `proxy_curl /realms/inventory/.well-known/openid-configuration | jq -r .issuer`, `status_of /admin/master/console/`, `kcadm_login` then `kcadm get realms/inventory --fields bruteForceProtected`.

## Practice tasks

- Print the certificate nginx presents with `kubectl -n keycloak exec deploy/tester -- sh -c "echo | openssl s_client -connect nginx:8443 -servername keycloak.localtest.me 2>/dev/null | openssl x509 -noout -subject"`.
- Change `proxy.headers` to `forwarded` while nginx still sends `X-Forwarded-*` headers, and look at the client address Keycloak records in its events or log. Put `xforwarded` back.
- Add `location /metrics` with `proxy_pass http://keycloak-service:9000;` to the ConfigMap, restart nginx, and see what an outside client can read. Then remove it again.
- Switch on brute force detection with a permanent lockout, lock `bob` out, and find out how long the lockout lasts. Unlock him through `attack-detection`.
- Try different `rate` and `burst` values for `limit_req` and count the `429` answers in a burst of 20 requests.
