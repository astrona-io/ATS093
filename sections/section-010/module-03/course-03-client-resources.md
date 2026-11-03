# Client Resources

A client is an application that asks Keycloak to sign users in. Creating it with `kcadm.sh` works, but it lives outside the Git repository that describes the rest of the deployment. The operator ships two custom resources that describe a client the same way a `Keycloak` resource describes the server: `KeycloakOIDCClient` and `KeycloakSAMLClient`. This part reads the schema of the first and explains how the operator treats it.

## The schema

The resources are in the group `k8s.keycloak.org`, in the API version `v2alpha1`. The alpha version means the fields can still change between releases, so check the schema of your operator before you rely on it:

<!-- astrona:playground:renew -->

```sh
kubectl explain keycloakoidcclient.spec
kubectl explain keycloakoidcclient.spec.client
```

The `spec` has three required fields:

| Field | What it does |
| --- | --- |
| `keycloakCRName` | The name of the `Keycloak` resource, in the same namespace, that receives the client. It cannot be changed after creation |
| `realm` | The realm that holds the client. It cannot be changed after creation |
| `client` | The client itself |

Inside `client`, the fields describe the application: `displayName`, `description`, `enabled`, `appUrl`, `redirectUris`, `webOrigins`, `roles`, `serviceAccountRoles`, `loginFlows` and `auth`. The list `loginFlows` takes the values `STANDARD`, `IMPLICIT`, `DIRECT_GRANT`, `SERVICE_ACCOUNT`, `DEVICE`, `CIBA` and `TOKEN_EXCHANGE`, and each one switches on one way for the client to get a token. The block `auth` sets the authentication method, and its `secretRef` points at a Secret key that holds the client secret, so the secret stays out of the resource.

## What the operator does

A client resource is declarative: the operator compares it with the client in Keycloak and updates the client when the resource changes. This differs from the realm import. The status carries `conditions`, an `observedGeneration`, a `hash` of the applied specification and the `uuid` of the client in Keycloak. The condition messages say when the client could not be created, for example because the realm does not exist.

An example for a confidential client, saved as `oidcclient-probe.yaml`:

```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: KeycloakOIDCClient
metadata:
  name: probe
  namespace: keycloak
spec:
  keycloakCRName: keycloak
  realm: inventory
  client:
    displayName: Probe service
    enabled: true
    redirectUris:
      - https://probe.example.com/*
    loginFlows:
      - STANDARD
```

Apply it with `kubectl apply -f oidcclient-probe.yaml`, then read the status of the resource. If the status stays empty, read the operator log and the description of the resource; the client API must be available in the Keycloak version and configuration you run. Whether a client resource works in your setup depends on the operator and server pair, which is why the check belongs in the habit: apply, read the conditions, then look in the realm with `kcadm get clients`.

You now have three ways to create a client and know when each applies. The last part is about keeping them all consistent.

## Common pitfalls

> [!WARNING]
> - **Treating `v2alpha1` as stable.** Check `kubectl explain` for the operator you run.
> - **Changing `realm` or `keycloakCRName` in an existing resource.** The API server refuses it; create a new resource instead.
> - **Writing a client secret into the resource.** Use `auth.secretRef`.
> - **Creating the same client by hand and by resource.** The two then disagree about who owns it.
