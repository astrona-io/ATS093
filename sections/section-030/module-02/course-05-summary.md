# Summary

The hostname, the certificate and the trusted headers together decide whether a client sees the right server.

## What you learned

`hostname` sets the public URL that Keycloak writes into every token and redirect. `hostname-admin` moves the console, and `hostname-backchannel-dynamic` lets internal clients use an internal URL. `hostname-strict=false` trusts request headers and invites host header injection. A fixed hostname gives the same issuer for every client.

A certificate is judged by its subject alternative names and its dates. Replacing a TLS Secret means creating the pair, applying the Secret and restarting the workload that read it; then you check what is served. Keycloak trusts the Java truststore plus the authorities in `spec.truststores`, and `db-tls-mode=verify-server` checks the database certificate.

Mutual TLS adds a client certificate. `https-client-auth` has `none`, `request` and `required`. Behind a proxy the certificate travels in a header, which is safe only when the proxy overwrites it and Keycloak accepts connections only from the proxy. Certificate bound tokens make a stolen token useless alone. Diagnose in order: network, handshake, proxy, URLs, issuer. The key facts to remember are these:

- Clients match the subject alternative name, not the common name.
- Restart the proxy after you replace its certificate, then verify with `openssl s_client`.
- A fixed `hostname` keeps the issuer the same whatever the request header says.
- Never trust a client certificate header unless the proxy overwrites it.

<!-- astrona:playground:destroy -->
