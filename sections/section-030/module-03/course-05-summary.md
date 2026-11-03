# Summary

Hardening is a set of decisions you can read back and test. Defaults favour getting started, so each one is yours to change.

## What you learned

A password policy is one string of rules joined with `and`; length and a blacklist beat a list of character classes, and the policy applies when a password is set. Hashing is slow on purpose and costs CPU on every sign-in. A second factor must be required, starting with administrators.

Access tokens should be short, because they cannot be revoked at the resource server. `revokeRefreshToken` makes refresh tokens single use, and a replay ends the session. Login events and administration events are off by default; they record who signed in and who changed what, they need an expiration, and they alert nobody until something reads them.

The server needs named administrators with a second factor instead of the bootstrap account, unused features disabled, the management port kept internal, limits on threads and queue, strict browser headers, and secrets kept in Secrets. A checklist read from the live system, with expected values in version control, finds drift. The key facts to remember are these:

- A policy you have not seen refuse something is a policy you do not know works.
- Make refresh tokens single use, and test the clients first.
- Events record but do not alert; read them somewhere.
- The bootstrap administrator is temporary; replace it.

<!-- astrona:playground:destroy -->
