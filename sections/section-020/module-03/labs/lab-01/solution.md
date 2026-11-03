# Solution: Fix The Disruption Budget

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the allowed disruptions of the budget, the rule it uses, and that Keycloak is untouched.

## Step 1: Read the budget

```sh
kubectl -n keycloak get pdb keycloak
kubectl -n keycloak get pdb keycloak -o jsonpath='{.spec}{"\n"}'
```

The budget has `minAvailable: 2` and the cluster has two pods, so `ALLOWED DISRUPTIONS` is `0`. A drain can never evict a pod, because that would take the number of available pods below the minimum.

## Step 2: Change the rule

Replace `minAvailable` with `maxUnavailable: 1`. Set the old field to `null` in a merge patch so it is removed, because a budget may carry only one of them:

```sh
kubectl -n keycloak patch pdb keycloak --type merge -p '{"spec":{"minAvailable":null,"maxUnavailable":1}}'
```

## Step 3: Check the result and submit

```sh
kubectl -n keycloak get pdb keycloak
```

The column `ALLOWED DISRUPTIONS` shows `1`, and the column `MAX UNAVAILABLE` shows `1`. Then submit:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```
