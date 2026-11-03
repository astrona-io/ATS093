# Sessions, Tokens And Events

Hardening a sign-in is half the work. The other half is limiting what a token can do when it escapes, and keeping a record that lets you find out that it did.

## How long things live

Each lifetime is a trade between convenience and exposure. These are the settings that matter, all in the realm settings:

| Setting | Field | What it controls |
| --- | --- | --- |
| Access token lifespan | `accessTokenLifespan` | How long a bearer token is accepted by a resource server |
| SSO session idle | `ssoSessionIdleTimeout` | A session ends after this long without activity |
| SSO session max | `ssoSessionMaxLifespan` | A session ends after this long even with activity |
| Offline session idle | `offlineSessionIdleTimeout` | How long an offline token lasts without use |
| Login timeout | `accessCodeLifespanLogin` | How long a user has to finish a sign-in |

A short access token is the strongest control, because a resource server cannot ask Keycloak whether a token was revoked unless it calls introspection; it trusts the signature until the token expires. Five minutes is common. A longer session lets a refresh token get a new access token without a new sign-in, so a short access token does not make users sign in more often.

## Refresh token revocation

By default a refresh token can be used again until it expires. If an attacker copies it, both the user and the attacker can keep using it, and nobody notices. The setting `revokeRefreshToken` makes each refresh token single use: the response to a refresh carries a new refresh token, and the old one stops working.

```sh
kcadm update realms/inventory -s revokeRefreshToken=true
```

With revocation on, a second use of a token that was already used is a sign of theft or of a client that does not store the new token. Keycloak ends the session when a used token is replayed. The setting `refreshTokenMaxReuse` allows a small number of reuses, for clients that retry on network errors; keep it at `0` unless you have a client that needs it. Test your clients before you switch it on, because a client that ignores the new refresh token will fail on its second refresh.

## Events

Keycloak has two event streams, and both are off by default.

- **Login events** record what happens to users and clients: sign-in, sign-out, failed login, password change, token refresh and errors. They answer who signed in from where and who failed to.
- **Administration events** record changes to the configuration: who created a client, changed a role, updated a realm. They answer who changed it. With details enabled they include the representation that was written.

```sh
kcadm update realms/inventory -s eventsEnabled=true -s adminEventsEnabled=true -s adminEventsDetailsEnabled=true
kcadm get events -r inventory -q max=5
kcadm get admin-events -r inventory -q max=5
```

Events are stored in the database. Set an expiration, because the table grows with every request, and choose which event types to save so that token refreshes do not fill it. Event listeners send events elsewhere: the default listener writes to the server log, which a log collector can ship. Administration event details can contain personal data and secrets, so restrict who can read them and shorten their retention.

## What events do not do

Events record; they do not alert. A failed login event is useful only if something reads it. Ship the log or the events to a system that can alert on bursts of failures, on new administrators, and on changes to client redirect URIs. That wiring belongs to the observability section.

## Mission

The realm `inventory` accepts any password, records nothing and lets a refresh token be used repeatedly. In the graded lab you set a password policy, turn on the two event streams and make refresh tokens single use, then check that a short password is refused and that `alice` can still sign in.

<!-- astrona:playground:renew -->
