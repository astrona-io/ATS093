# Certificates And Trust

A certificate has a short list of properties that matter in practice: the names it covers, the dates it is valid, who signed it, and whether the private key is protected. Most outages come from the first two.

## Where TLS ends

When TLS ends on nginx, Keycloak speaks HTTP inside the cluster. The certificate belongs to the proxy, and the Secret `edge-tls` holds it. The other two designs differ in where the certificate lives:

| Design | Certificate on | Keycloak setting |
| --- | --- | --- |
| Edge termination | The proxy | `http.httpEnabled: true`, `proxy.headers` set |
| Re-encrypt | The proxy and Keycloak | `http.tlsSecret` names the Secret; the proxy verifies it |
| Passthrough | Keycloak only | `http.tlsSecret`; the proxy forwards the bytes |

For Keycloak's own certificate, `spec.http.tlsSecret` references a Secret of type `kubernetes.io/tls`, and the operator mounts it. The certificate must name the host that the proxy uses to reach Keycloak, for example the Service name, or the proxy cannot verify it.

## Read a certificate

Know the three commands, because they answer most questions:

```sh
served_cert "-subject -issuer -dates"
served_cert "-ext subjectAltName"
served_cert "-checkend 2592000" && echo "valid for at least 30 days"
```

Clients match the name against the **subject alternative name**, not the common name. A certificate with the right common name and no alternative names fails in current browsers and libraries. `-checkend` takes seconds and exits with a failure when the certificate ends within that time, which makes it a good probe for monitoring.

## Replace a certificate

A certificate does not renew itself. The steps for a Secret that a Deployment mounts are:

1. Create the new certificate and key.
2. Replace the Secret. `kubectl create secret tls` fails when it exists, so render it and apply: `kubectl create secret tls edge-tls --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl apply -f -`.
3. Make the workload read it. nginx loads the certificate at start, so run `kubectl rollout restart deployment/nginx`. A mounted Secret file updates on disk after a while, but nginx does not look at it again.
4. Check what is served, not what you stored. The fingerprint on the wire must equal the fingerprint in the Secret.

Automate the steps with a certificate manager in production. A manager renews before expiry, writes the Secret, and some workloads can be told to reload on a change. Still alert on the remaining lifetime, because an automation that has silently failed looks exactly like one that works until the day it expires.

## Trust: what Keycloak believes

Keycloak is also a client. It calls identity providers, user federation, the database and webhooks, and it must trust the certificates of those servers. The default is the Java truststore plus whatever you add. In the `Keycloak` resource, add certificate authorities with `spec.truststores`, a map from a name to a Secret or a ConfigMap with the PEM files:

```yaml
spec:
  truststores:
    corporate-ca:
      secret:
        name: corporate-ca
```

The operator mounts the files and sets `truststore-paths`. For the database, `db-tls-mode=verify-server` makes Keycloak check the database certificate against that truststore, which protects against DNS poisoning and address hijacking. Never turn verification off to silence an error; add the missing authority instead.

## Mission

nginx presents a certificate for the wrong name that expires soon. In the graded lab you create a new certificate, replace the Secret `edge-tls`, restart nginx, and prove with `openssl` that the served certificate is the new one.

<!-- astrona:playground:renew -->
