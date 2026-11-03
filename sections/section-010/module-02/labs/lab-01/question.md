# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Resources, scheduling and log format in the Keycloak resource

## Scenario

A `Keycloak` resource named `keycloak` runs in the namespace `keycloak`. The platform team copied it from a production cluster with much larger nodes. Here the pod `keycloak-0` stays `Pending` and Keycloak never starts. The monitoring team also wants the console log as JSON, one object per line, and the platform team wants the pod spread across nodes when there is more than one node.

## Your task

In the namespace `keycloak`, change the `Keycloak` resource so that:

1. The Keycloak container requests `768Mi` of memory and `250m` of CPU, and has a memory limit of `1536Mi`.
2. Keycloak writes its console log as JSON (`log-console-output`). Keep `health-enabled` set to `true`.
3. The pod has a topology spread constraint with `maxSkew` `1` on the key `kubernetes.io/hostname` and `whenUnsatisfiable: ScheduleAnyway`.

## Constraints

- Change the `Keycloak` resource only. Do not edit the StatefulSet or the pod by hand.
- Do not delete and recreate the `Keycloak` resource.
- Keep the database settings as they are.
- If the pod stays `Pending` after your change, find out why before you try anything else.

## Done when

- The `Keycloak` resource reports `Ready=True` with one ready pod.
- The pod `keycloak-0` requests `768Mi` and `250m` and has a memory limit of `1536Mi`.
- The pod carries the topology spread constraint from the resource.
- The last log line of `keycloak-0` is a JSON object.
