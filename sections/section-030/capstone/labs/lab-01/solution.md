# Solution: Harden The Keycloak Edge

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks seven things: the issuer through nginx, the proxy headers, the private paths, the brute force settings, a real lockout of `bob`, a `429` in a burst, and a token for `alice` with the public issuer.

## Step 1: Reproduce every finding

Paste the helper, then check the issuer and every path through nginx:

```sh
proxy_curl() {
  NGINX_IP=$(kubectl -n keycloak get service nginx -o jsonpath='{.spec.clusterIP}')
  kubectl -n keycloak exec deploy/tester -- curl -sk \
    --resolve "keycloak.localtest.me:8443:$NGINX_IP" "${@:2}" "https://keycloak.localtest.me:8443$1"
}
proxy_curl /realms/inventory/.well-known/openid-configuration | jq -r .issuer
for request_path in /admin/master/console/ /realms/master/.well-known/openid-configuration /metrics /health/ready; do
  echo "$request_path $(proxy_curl "$request_path" -o /dev/null -w '%{http_code}')"
done
kubectl -n keycloak get configmap nginx-conf -o jsonpath='{.data.keycloak\.conf}'
```

The issuer is the internal `http://keycloak-service:8080` address. The console and the master realm are reachable, and the configuration forwards `/` to port `8080` and `/metrics` to the management port `9000`, with no `X-Forwarded-*` headers and no rate limit.

## Step 2: Fix the Keycloak resource

Set the public hostname, the internal administration address and the proxy headers:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p \
  '{"spec":{"hostname":{"hostname":"https://keycloak.localtest.me:8443","admin":"http://localhost:8080"},"proxy":{"headers":"xforwarded"}}}'
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

## Step 3: Switch on brute force detection

```sh
kcadm() {
  kubectl -n keycloak exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master \
  --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
  --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
kcadm update realms/inventory -s bruteForceProtected=true -s failureFactor=5 \
  -s permanentLockout=false -s waitIncrementSeconds=60 -s maxFailureWaitSeconds=900
```

## Step 4: Replace the nginx configuration

One new configuration closes the remaining findings: only the public paths, the `X-Forwarded-*` headers, `403` for the console and the master realm, `404` for everything else (including `/metrics` and `/health`), and a rate limit on the token endpoint.

Save this as `configmap-nginx-conf.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: keycloak
data:
  keycloak.conf: |
    limit_req_zone $binary_remote_addr zone=token_endpoint:10m rate=5r/s;

    server {
      listen 8443 ssl;
      server_name keycloak.localtest.me;
      ssl_certificate     /etc/nginx/tls/tls.crt;
      ssl_certificate_key /etc/nginx/tls/tls.key;

      proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host  $host;
      proxy_set_header X-Forwarded-Port  $server_port;

      location /admin/        { return 403; }
      location /realms/master/ { return 403; }

      location ~ ^/realms/[^/]+/protocol/openid-connect/token$ {
        limit_req zone=token_endpoint burst=5 nodelay;
        limit_req_status 429;
        proxy_pass http://keycloak-service:8080;
      }

      location /realms/      { proxy_pass http://keycloak-service:8080; }
      location /resources/   { proxy_pass http://keycloak-service:8080; }
      location /.well-known/ { proxy_pass http://keycloak-service:8080; }

      location / { return 404; }
    }
```

Apply it:

```sh
kubectl apply -f configmap-nginx-conf.yaml
```

Then restart nginx so it reads the file:

```sh
kubectl -n keycloak rollout restart deployment/nginx
kubectl -n keycloak rollout status deployment/nginx
```

## Step 5: Prove each finding is closed

Run the commands from step 1 again: the issuer is the public `https://` address, and the four internal paths answer `403` or `404`. Then prove the lockout with `bob` straight against the Keycloak Service, and unlock him again. The password grant is used only to try passwords from a terminal; OAuth 2.1 drops it:

```sh
for attempt in 1 2 3 4 5 6; do
  kubectl -n keycloak exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code} ' http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli -d username=bob -d password=wrong-password
done; echo
BOB_ID=$(kcadm get users -r inventory -q username=bob -q exact=true --fields id --format csv --noquotes)
kcadm get attack-detection/brute-force/users/$BOB_ID -r inventory | jq .disabled
kcadm delete attack-detection/brute-force/users/$BOB_ID -r inventory
```

Last, a burst through nginx for a user that does not exist; `429` answers appear after the first few:

```sh
for attempt in $(seq 1 20); do
  printf '%s ' "$(proxy_curl /realms/inventory/protocol/openid-connect/token -o /dev/null -w '%{http_code}' \
    -d grant_type=password -d client_id=inventory-cli -d username=rate-limit-probe -d password=wrong)"
done; echo
```

Each `kubectl exec` in this loop takes some time, so it may send fewer than five requests per second and show no `429`. In that case, run the burst inside the `tester` pod as one `sh -c` loop, the way the grader does.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove only `location /metrics` | `/`, and with it `/admin/` and the master realm, is still forwarded |
| `hostname-strict: false` instead of a fixed hostname | Keycloak trusts any host header a client sends |
| Permanent lockout | Anyone can lock any user out for good |
| Rate limit on every path | The sign-in pages break for real users |

## Common mistakes

- Fixing nginx but not restarting it.
- Testing the lockout through nginx after the rate limit is in place; the `429` answers never count as failed logins.
- Forgetting `hostname.admin`, and with it the administrators' way in.
