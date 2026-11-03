# Solution: Set Resources, Scheduling And Log Format

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the resource is `Ready`, the pod has the requested resources, the pod carries the spread constraint, and the last log line is JSON.

## Step 1: Find why the pod is Pending

List the pods and read the events of `keycloak-0`:

```sh
kubectl -n keycloak get pods
kubectl -n keycloak describe pod keycloak-0 | tail -8
```

The pod is `Pending`. The scheduler event says that no node has enough memory. The request in the resource is `64Gi`, which no node of the playground cluster has. The scheduler places a pod only on a node that can give the full request, so the pod waits.

## Step 2: Change the Keycloak resource

Save this as `keycloak-patch.yaml`:

```yaml
spec:
  resources:
    requests:
      memory: 768Mi
      cpu: 250m
    limits:
      memory: 1536Mi
  scheduling:
    topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: keycloak
  additionalOptions:
    - name: health-enabled
      value: "true"
    - name: log-console-output
      value: json
```

Apply it as a merge patch:

```sh
kubectl -n keycloak patch keycloak keycloak --type merge --patch-file keycloak-patch.yaml
```

A merge patch replaces a list as a whole, so `additionalOptions` in the file keeps `health-enabled` and adds the log option.

## Step 3: Replace the pod that never started

The operator updates the StatefulSet pod template. A StatefulSet does not replace a pod that never became ready, so `keycloak-0` can keep the old template. Delete the pod once, and the StatefulSet creates it again from the new template:

```sh
kubectl -n keycloak delete pod keycloak-0
kubectl -n keycloak wait --for=condition=Ready pod/keycloak-0 --timeout=600s
```

## Step 4: Check the three results

Read the resources and the spread constraint from the pod, and the last log line:

```sh
kubectl -n keycloak get pod keycloak-0 -o jsonpath='{.spec.containers[0].resources}{"\n"}{.spec.topologySpreadConstraints}{"\n"}'
kubectl -n keycloak logs keycloak-0 --tail=1
```

The resources show the requests and the limit from the resource, the pod carries the constraint, and the log line starts with `{`. Then submit:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```
