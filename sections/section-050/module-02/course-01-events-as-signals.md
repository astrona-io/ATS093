# Events As Signals

A realm can record what users and administrators do. These records answer questions the log is poor at, because they are structured, filterable and kept for as long as you decide.

## Two stores, two questions

| Store | Records | Typical question |
| --- | --- | --- |
| Login events | Sign-ins, failures, logouts, token refreshes, password changes | Who failed to sign in, from where, with what error? |
| Administration events | Creates, updates and deletes of realm objects | Who changed this client, and what did it look like? |

Both are off by default and per realm. They are kept in the database, so set an expiration: the table grows with every request. Choose the event types you save, so that token refreshes, which are frequent, do not push out the failures you care about.

```sh
kcadm update realms/inventory -s eventsEnabled=true -s eventsExpiration=604800
kcadm get events -r inventory -q type=LOGIN_ERROR -q max=10
```

A `LOGIN_ERROR` event carries the error (`invalid_user_credentials`, `user_not_found`, `user_disabled`) and the client and address, which tells apart a typing mistake, a guessing attack and a broken client.

## Listeners

An event listener receives each event as it happens. The default one, `jboss-logging`, writes it to the server log. Others can send the event to a queue or a webhook; those are extensions you install. Events reach the log even if the store is off, when the listener is configured.

## Events as metrics

Events can also be counted. With the user event metrics enabled, a failed login increments a counter per realm. A metric is cheap and good for graphs and alerts; an event holds the detail and is good for the investigation. Use the metric to notice, and the event to find out.

| You want to | Use |
| --- | --- |
| Alert when failed logins rise | A metric |
| Find which address is guessing | Login events |
| Find who changed a redirect URI | Administration events |
| See what the server did in the last minute | The log |

## Privacy and size

Events hold user ids, addresses and, for administration events with details, the representation that was written, which can include secrets. Limit who can read them, shorten their retention, and do not copy them into places that have weaker controls than Keycloak itself.

## The limits of events

Events are written after the fact and do not stop anything. A repeated `LOGIN_ERROR` does not lock an account by itself; brute force detection does that. And an event for a request that never reached Keycloak, such as a request refused at the proxy, does not exist. Look at the proxy log for those.
