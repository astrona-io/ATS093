# Solution: Expose Keycloak Through An Edge Proxy

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the issuer through nginx, the proxy headers on both sides, the private paths, and a token through nginx with the public issuer.

## Step 1: See the edge from the outside

Paste a helper that requests a path through nginx under the public name:

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
```

The issuer is `http://keycloak-service:8080/realms/inventory`: an internal address over plain HTTP. The administration console and the master realm answer `200` or a redirect, so they are public, and `/metrics` may answer too, because nginx forwards it to the management port.

## Step 2: Tell Keycloak what the world sees

Read the hostname and proxy settings of the resource:

```sh
kubectl -n keycloak get keycloak keycloak -o jsonpath='{.spec.hostname} {.spec.proxy}{"\n"}'
```

The hostname is the internal address, and there is no `proxy` block. Set the public hostname, the internal administration address and the proxy headers:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge -p \
  '{"spec":{"hostname":{"hostname":"https://keycloak.localtest.me:8443","admin":"http://localhost:8080"},"proxy":{"headers":"xforwarded"}}}'
kubectl -n keycloak rollout status statefulset/keycloak --timeout=600s
kubectl -n keycloak wait keycloak/keycloak --for=condition=Ready --timeout=600s
```

## Step 3: Rewrite the nginx configuration

The current configuration forwards `/` and `/metrics` and sets no headers. Replace it with one that forwards only the public paths and overwrites the `X-Forwarded-*` headers.

Save this as `configmap-nginx-conf.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
  namespace: keycloak
data:
  keycloak.conf: |
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

Then restart nginx, because it reads its configuration only at start:

```sh
kubectl -n keycloak rollout restart deployment/nginx
kubectl -n keycloak rollout status deployment/nginx
```

## Step 4: Check from the outside again

Run the commands from step 1 again. The issuer is now `https://keycloak.localtest.me:8443/realms/inventory`. The console and the master realm answer `403`, and `/metrics` and `/health/ready` answer `404`, all from nginx.

Then request a token for `alice` through nginx and read its issuer. The password grant is used here only to test from a terminal; OAuth 2.1 drops it:

```sh
proxy_curl /realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=alice-password \
  | jq -r '.access_token | split(".")[1] | gsub("-";"+") | gsub("_";"/") | . + ("=" * ((4 - (length % 4)) % 4)) | @base64d | fromjson | .iss'
```

The issuer is the public address.

## Step 5: Check the administrators' way in

Start a port-forward in a second terminal and open `http://localhost:8080/admin/` in a browser; the console loads on the internal address set in `hostname.admin`:

```sh
kubectl -n keycloak port-forward svc/keycloak-service 8080:8080
```

## Step 6: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set only `proxy.headers` and keep the internal hostname | With a fixed hostname, Keycloak keeps building the internal address; the issuer stays wrong |
| Set `hostname-strict` to `false` and rely on the headers | Keycloak then trusts any host a client sends. The fixed public hostname is the safer fix |
| Block `/admin/` and leave `/` forwarded | `/realms/master/` and `/metrics` stay public |
| Change the ConfigMap without restarting nginx | nginx keeps serving the old configuration |

## Common mistakes

- Forgetting `hostname.admin`. With only the public hostname, the console tries to load from the public address, where nginx blocks it.
- Leaving `location /metrics` in the configuration. It forwards to port `9000`, which must never be public.
- Checking right after the patch. The operator replaces the Keycloak pod first; wait for the rollout.
