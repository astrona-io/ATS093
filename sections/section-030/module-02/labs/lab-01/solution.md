# Solution: Replace The Edge Certificate

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the name in the served certificate, its lifetime, and that nginx serves the certificate of the Secret.

## Step 1: Look at what nginx presents

```sh
kubectl -n keycloak exec deploy/tester -- sh -c \
  "echo | openssl s_client -connect nginx:8443 -servername keycloak.localtest.me 2>/dev/null | openssl x509 -noout -subject -dates -ext subjectAltName"
```

The subject and the alternative name are `old-keycloak.example.com`, and `notAfter` is close. Modern clients check the alternative name, not the subject, so the name is the main fault.

## Step 2: Create a new certificate

Create it in the tester pod and copy the two files out:

```sh
kubectl -n keycloak exec deploy/tester -- sh -c \
  'openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
     -subj "/CN=keycloak.localtest.me" \
     -addext "subjectAltName=DNS:keycloak.localtest.me" \
     -keyout /tmp/new.key -out /tmp/new.crt'
kubectl -n keycloak exec deploy/tester -- cat /tmp/new.crt > tls.crt
kubectl -n keycloak exec deploy/tester -- cat /tmp/new.key > tls.key
```

## Step 3: Replace the Secret and restart nginx

`kubectl create` fails because the Secret exists. Render it and apply it instead:

```sh
kubectl -n keycloak create secret tls edge-tls --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl apply -f -
kubectl -n keycloak rollout restart deployment/nginx
kubectl -n keycloak rollout status deployment/nginx --timeout=300s
```

nginx reads the certificate when it starts, so the restart is needed.

## Step 4: Check the result and submit

```sh
kubectl -n keycloak exec deploy/tester -- sh -c \
  "echo | openssl s_client -connect nginx:8443 -servername keycloak.localtest.me 2>/dev/null | openssl x509 -noout -dates -ext subjectAltName"
```

The alternative name is `DNS:keycloak.localtest.me` and `notAfter` is a year away. Then submit:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```
