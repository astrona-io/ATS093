# Solution: Stop Password Guessing

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-02` after a step tells you which checks pass. The lockout check unlocks `bob` again when it is done.

The grader checks four things: the brute force settings, a real lockout of `bob`, a `429` from nginx in a burst, and a normal token for `alice`.

## Step 1: Switch on brute force detection

Sign `kcadm.sh` in with the initial admin Secret, read the current settings, then change them:

```sh
kcadm() {
  kubectl -n keycloak exec -i keycloak-0 -- \
    /opt/keycloak/bin/kcadm.sh "$@" --config /tmp/kcadm.config
}
kcadm config credentials --server http://localhost:8080 --realm master \
  --user "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 -d)" \
  --password "$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)"
kcadm get realms/inventory --fields bruteForceProtected,failureFactor,permanentLockout
kcadm update realms/inventory -s bruteForceProtected=true -s failureFactor=5 \
  -s permanentLockout=false -s waitIncrementSeconds=60 -s maxFailureWaitSeconds=900
```

`bruteForceProtected` was `false`. Now Keycloak counts failed logins per user and locks a user out for 60 seconds after five failures, for longer after repeated lockouts, up to 900 seconds.

## Step 2: Prove the lockout

Send six wrong passwords for `bob` straight to the Keycloak Service, then read his lockout state. The password grant is used only to try passwords from a terminal; OAuth 2.1 drops it:

```sh
for attempt in 1 2 3 4 5 6; do
  kubectl -n keycloak exec deploy/tester -- \
    curl -s -o /dev/null -w '%{http_code} ' http://keycloak-service:8080/realms/inventory/protocol/openid-connect/token \
      -d grant_type=password -d client_id=inventory-cli -d username=bob -d password=wrong-password
done; echo
BOB_ID=$(kcadm get users -r inventory -q username=bob -q exact=true --fields id --format csv --noquotes)
kcadm get attack-detection/brute-force/users/$BOB_ID -r inventory
kcadm delete attack-detection/brute-force/users/$BOB_ID -r inventory
```

Every attempt answers `401`, and the lockout state shows `disabled` as `true`. The last command unlocks `bob` again.

## Step 3: Add the rate limit to nginx

The new configuration keeps the existing one and adds a shared counter (`limit_req_zone`, keyed by the client's address, five requests per second) and a location for the token endpoint that applies it with a burst of five and answers `429` above it.

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

## Step 4: Prove the rate limit

Send 30 requests as fast as the `tester` pod can, for a user name that does not exist, so no real account gets locked:

```sh
NGINX_IP=$(kubectl -n keycloak get service nginx -o jsonpath='{.spec.clusterIP}')
kubectl -n keycloak exec deploy/tester -- sh -c "for attempt in \$(seq 1 30); do \
  curl -sk -o /dev/null -w '%{http_code} ' --resolve keycloak.localtest.me:8443:$NGINX_IP \
    https://keycloak.localtest.me:8443/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=inventory-cli -d username=rate-limit-probe -d password=wrong; done; echo"
```

The first answers are `401` from Keycloak; then `429` answers from nginx appear. Wait a few seconds, then check that a normal sign-in still works:

```sh
kubectl -n keycloak exec deploy/tester -- curl -sk --resolve keycloak.localtest.me:8443:$NGINX_IP \
  https://keycloak.localtest.me:8443/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=inventory-cli -d username=alice -d password=alice-password | jq -r 'has("access_token")'
```

The answer is `true`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-02
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `permanentLockout=true` | Anyone who knows a user name can lock that user out until an administrator steps in. The grader rejects it |
| `limit_req` on `location /` or `/realms/` | The sign-in page loads several files at once and starts failing for real users |
| A rate so low that one request per second passes | Normal sign-ins after a redirect can already need several requests; `alice` may fail the last check |
| Edit the ConfigMap without restarting nginx | nginx keeps the old configuration and answers no `429` |

## Common mistakes

- Testing the lockout through nginx after adding the rate limit. The `429` answers never reach Keycloak and do not count as failed logins.
- Testing with `alice` and locking her out; use `bob` or a user that does not exist.
- Losing the `X-Forwarded-*` lines when rewriting the configuration.
