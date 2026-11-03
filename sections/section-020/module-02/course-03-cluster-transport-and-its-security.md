# Cluster Transport And Its Security

The caches work only while the pods can talk to each other. This part covers how the pods find each other, how the traffic between them is protected, and how Keycloak spreads the copies of an entry so one failure does not lose it.

## The cache stack

The cache stack is the combination of the transport protocol and the way members are discovered. You choose it with the build option `cache-stack`:

| Stack | Transport | Discovery |
| --- | --- | --- |
| `jdbc-ping` (default) | TCP | The pods register in a table of the Keycloak database |
| `jdbc-ping-udp` (deprecated) | UDP | The same table |
| `kubernetes` (deprecated) | TCP | DNS lookup of the headless service, needs `jgroups.dns.query` |
| `tcp`, `udp` (deprecated) | TCP, UDP | IP multicast |
| `ec2`, `azure`, `google` (deprecated) | | Cloud APIs |

On Kubernetes with the operator keep `jdbc-ping`. It needs nothing beyond the database that exists already, and the operator's network policy already opens its ports between the pods. With the multicast stacks, two clusters in one network must use different multicast addresses or ports or their pods join each other.

## Cluster name and node name

Pods find each other in the database, so two clusters that share one database would merge into one. The cluster name prevents that: only members with the same `cache-embedded-cluster-name` (default `ISPN`) join. The option exists for the `stateless` design with independent clusters, and changing it without that feature leaves the caches of the clusters without invalidation messages between them.

The node name, `cache-embedded-node-name`, is random on every start by default. A stable name makes logs and dashboards easier to follow across restarts. On Kubernetes, a StatefulSet pod name such as `keycloak-0` is already stable, so use the option when your monitoring needs the name inside Infinispan metrics.

## Encryption between the pods

For a TCP based stack the transport is encrypted with mutual TLS by default, and no option is needed. Keycloak creates a self-signed RSA 2048 bit certificate, stores it with its key in the database so all pods can read it, and uses TLS 1.3. The certificate is valid for 60 days and is replaced every 30 days at runtime. Change the interval with `cache-embedded-mtls-rotation-interval-days`.

You can bring your own material with `cache-embedded-mtls-key-store-file` and `cache-embedded-mtls-key-store-password` for the key store, and `cache-embedded-mtls-trust-store-file` and `cache-embedded-mtls-trust-store-password` for the trust store. This is not recommended for a standard setup. If you do it, use a separate self-signed certificate for each Keycloak deployment, so one cluster cannot join another.

The UDP stacks and `TCP_NIO2` are not covered by the automatic encryption. For those, set `cache-embedded-mtls-enabled` to `false` and follow the JGroups encryption documentation.

## A service mesh in the way

A mesh such as Istio can break the pod to pod certificate exchange. The log then shows `JGRP000006: failed accepting connection from peer SSLSocket`, and the cluster does not form. You have two choices: let the mesh pass the Keycloak traffic untouched, or turn the Keycloak encryption off and trust the mesh. For the first, create a `PeerAuthentication` for the Keycloak pods with port `7800` in `PERMISSIVE` mode. For the second, set `cache-embedded-mtls-enabled` to `false` and authorise only traffic between Keycloak pods on the data port. Do not turn encryption off and leave the port open to the whole mesh.

## Ports and the bind address

| Port | Use |
| --- | --- |
| `7800` | Data between members, set by `cache-embedded-network-bind-port` |
| `57800` | Failure detection, an offset of 50000 from the data port |

By default the pod binds to a site-local address (for example in `10.0.0.0/8`). If the pod has several interfaces, set `cache-embedded-network-bind-address` to an address, or to `GLOBAL`, `NON_LOOPBACK` or `match-interface:<regex>`. Make sure the address is reachable from every other member.

## Where the copies live

A distributed entry has owners, for example two copies on two pods. Keycloak can ask Infinispan to place the owners on different sites, racks or machines through `spi-cache-embedded--default--site-name`, `--rack-name` and `--machine-name`. The operator sets the machine name from the Kubernetes node itself, so two copies of an entry do not end up on the same node when there is a choice. That only helps if the pods are on different nodes, so add pod anti-affinity or topology spread constraints in `spec.scheduling`.

User and client sessions are safe in the database, so these options protect the remaining distributed caches: authentication sessions, action tokens and similar short-lived data.

## Try it

Open the clustering log lines of a pod and the environment of the other pod, and find the port:

```sh
kubectl -n keycloak logs keycloak-0 | grep -E "ISPN000094|JGRP" | tail -3
kubectl -n keycloak get networkpolicy
```

The `ISPN000094` line lists both members. The network policy of the operator is the reason the data port is open between the pods and nowhere else.
