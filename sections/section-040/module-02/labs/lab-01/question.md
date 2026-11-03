# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Exporting a realm for reuse

## Scenario

The realm `inventory` in the namespace `keycloak` must be recreated in another environment from a file kept in version control. You decided to start from a partial export of the live realm. The file must contain the configuration and must not contain any secret.

## Your task

1. Take a partial export of the realm `inventory` that includes its clients, groups and roles.
2. Save it as `/tmp/inventory-export.json` **inside the `tester` pod**.
3. The export hides the secret of the client `inventory-api` behind a mask. Replace that value in the file with the placeholder `${API_SECRET}`, so that an import can fill it from a Secret.
4. Leave the realm `inventory` as it is.

## Constraints

- Use the Administration REST API through the `tester` pod, or the console and copy the file in. The administrator credentials are in the Secret `keycloak-initial-admin`, and the API is at `http://keycloak-service:8080`.
- The file must be valid JSON. The real secret value must not appear in it.

## Done when

- The file holds the realm `inventory`, the clients `inventory-cli` and `inventory-api`, the realm role `auditor` and the group `ops`.
- The secret of `inventory-api` in the file is `${API_SECRET}`, and no mask or real secret remains.
- `alice` still gets a token from the realm.
