# Harden The Realm And The Server

A fresh Keycloak is built to be easy to start, not to be hard to attack. It accepts any password, remembers nothing about who did what, lets a refresh token be used until it expires, and runs with an administrator account that anyone who knows the initial Secret can use. None of these is a bug. Each is a default that a production system should change on purpose.

This module hardens two things. The realm, which is the policy that applies to your users and applications, and the server, which is the process and the account that run it. Keep one sentence in mind: **hardening is a list of decisions you can read back, so every setting you change should be one you can name and verify.**

The module has four parts. **Password And Account Policies** covers password rules, hashing and second factors. **Sessions, Tokens And Events** covers lifetimes, refresh token revocation and the event log; a graded lab follows it. **The Server And The Administrator** covers the bootstrap account, disabled features, limits and headers. **A Hardening Review** puts them into a checklist that you can run on any realm.

## Learning objectives

After this module you can:

- Write a password policy and say what each rule protects against.
- Explain why password hashing is deliberately slow, and what that costs.
- Set session and token lifetimes, and make refresh tokens single use.
- Turn on login events and administration events and say what each records.
- Replace the bootstrap administrator with named accounts that use a second factor.
- Reduce the surface of the server with disabled features, network policy and limits.

## Before you start

You need the modules about the reverse proxy and about realms. You should know what a realm, a user, a client and a token are, and how `kcadm.sh` signs in.

Your playground is a single-node `kind` cluster. Everything runs in the namespace **`keycloak`**:

| Workload | What it is |
| --- | --- |
| `keycloak` | A `Keycloak` resource with one instance on PostgreSQL |
| `inventory` | The realm, with the users `alice` and `bob` and the public client `inventory-cli`; default security settings |
| `postgres` | PostgreSQL 17 with the database `keycloak` |
| `tester` | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
