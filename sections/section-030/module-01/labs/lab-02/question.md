# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Brute force detection and rate limiting

## Scenario

Keycloak runs in the namespace `keycloak` behind nginx, which ends TLS on port `8443` for `keycloak.localtest.me` and forwards only the public paths. The security team ran a password-guessing test against the token endpoint of the realm `inventory` last week. Nothing stopped it: no account was locked, and every request reached Keycloak.

The test user `bob` (password `bob-password`) exists in `inventory` for exactly this kind of check.

## Your task

In the namespace `keycloak`:

1. Turn on brute force detection in the realm `inventory`: lock a user out **temporarily** after **five** failed logins.
2. Limit the request rate to the token endpoint at nginx. A burst of requests from one client must be answered with `429 Too Many Requests` by nginx itself. The ConfigMap `nginx-conf` holds the nginx configuration.
3. Keep normal use working: `alice` (password `alice-password`) must still get a token through nginx from the client `inventory-cli`.

## Constraints

- **Temporary lockout only.** A permanent lockout lets anyone lock any user out for good.
- Rate limit the token endpoint only; the sign-in pages under `/realms/` load several files at once and must not be slowed down.
- Keep everything the nginx configuration already does: TLS, the `X-Forwarded-*` headers, and the blocked `/admin/` and `/realms/master/` paths.
- Change the realm with `kcadm.sh` or the console, not the database.

## Done when

- The realm `inventory` has `bruteForceProtected` `true`, `failureFactor` `5` and `permanentLockout` `false`.
- Six wrong passwords for `bob` leave him locked out.
- A burst of 30 requests to the token endpoint through nginx gets at least one `429`.
- `alice` gets a token through nginx after a short pause.
