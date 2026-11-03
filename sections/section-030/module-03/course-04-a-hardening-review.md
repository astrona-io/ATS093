# A Hardening Review

A list is the cheapest control there is. This part turns the module into a checklist you can run against any realm, and shows how to get the answers from the live system.

## The checklist

| Area | Check | How to read it |
| --- | --- | --- |
| Passwords | Length of at least 12, `notUsername`, a blacklist | `kcadm get realms/<realm> --fields passwordPolicy` |
| Second factor | Required for administrators | Authentication flow of the master realm |
| Brute force | Detection on, with a lockout | `--fields bruteForceProtected,failureFactor` |
| Tokens | Access token lifespan of a few minutes | `--fields accessTokenLifespan` |
| Refresh tokens | Revoked after use | `--fields revokeRefreshToken,refreshTokenMaxReuse` |
| Sessions | Idle and maximum limits you can justify | `--fields ssoSessionIdleTimeout,ssoSessionMaxLifespan` |
| Events | Login and administration events on, with an expiration | `--fields eventsEnabled,adminEventsEnabled,eventsExpiration` |
| Clients | No wildcard redirect URIs, public clients only where needed | `kcadm get clients -r <realm> --fields clientId,redirectUris,publicClient` |
| Administrators | Named accounts, bootstrap account removed | Users with admin roles |
| Server | Unused features off, management port internal | `Keycloak` resource, network policy |
| Edge | Admin console and master realm blocked from outside | Proxy configuration |

## Run it as a script

Put the reads into one script and run it after every change and on a schedule. The output is a record, and a difference between two runs is a finding:

```sh
kcadm_login
kcadm get realms/inventory --fields passwordPolicy,bruteForceProtected,accessTokenLifespan,revokeRefreshToken,eventsEnabled,adminEventsEnabled
kcadm get clients -r inventory --fields clientId,redirectUris,publicClient
```

Keep the expected values in version control next to the realm definition, and compare. A setting that someone changed by hand in the console is drift, and drift in security settings is the kind you want to notice.

## Common findings

- A client with the redirect URI `*`, which lets any site receive a code.
- A public client with direct access grants enabled when no one uses the password flow.
- The access token lifespan set to hours "for the batch job" instead of using a client with a service account.
- Events enabled with no expiration, which fills the database.
- The administration console reachable from the internet, because the proxy forwarded `/`.
- The initial admin Secret still in use a year after the installation.

## Order of work

Change one thing at a time and check that sign-in still works for a test user after each change. Start with what is cheap and reversible: policy, events and token settings. Then the changes that need the users to take part, such as a second factor, with notice. Then the changes that restart the server, such as disabled features, in a maintenance window. Record each change with the reason, because the next person must know whether a setting is deliberate.

## Verify, do not assume

A hardening setting that has never been seen to refuse something is only a hope. For each item, run the case it should block: a short password, a reused refresh token, a request to `/admin/` from outside, a sixth failed login. The lab of this module does that for the realm settings.
