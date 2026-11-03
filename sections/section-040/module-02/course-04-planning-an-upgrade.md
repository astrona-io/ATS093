# Planning An Upgrade

The operator rolls out a new image when the tag changes. This part is about what you do before you change the tag: reading what changed, and rehearsing on a copy.

## Read what changed

Each release has release notes and an upgrading guide. Read the guide for every version between yours and the target, not only the last one. Look for four kinds of change:

- **Removed or changed features and options.** A configuration option that was renamed stops working after the upgrade, and the server may refuse to start.
- **Behaviour changes.** A default that moved, such as the cache behaviour or a security setting, changes how the server acts with no change in your files.
- **Providers and themes.** Custom code built against the API of an older version must be rebuilt against the new one.
- **Database requirements.** The supported versions of the database move forward.

## Patch, minor and major

A patch release fixes bugs and security problems and is the easy case; the operator's `Auto` update strategy can roll such a change through the instances one at a time when the image allows it. A minor or major release can change the database schema and the cache format, so the instances are replaced together and there is a window with no service. Plan the window, tell the users, and expect that going back needs the database from before the upgrade.

## Rehearse on a copy

The rehearsal is the step that finds the surprise before production does:

1. Restore the latest dump into a new database.
2. Start a Keycloak of the target version against that database, with the same configuration as production.
3. Watch the migration in the log, and note how long it took.
4. Sign in as a test user, check a client of each type, and read the realm settings you rely on.
5. Run the checks that you will run after the real upgrade, and write down the result.

The time of the migration step is the length of your window. A small test database migrates quickly and a large one does not, so use a real copy.

## The order on the day

1. Take a fresh database dump and keep a copy of the resources and Secrets.
2. Announce the window and, if the plan needs it, put the proxy in maintenance mode.
3. Change the image in the `Keycloak` resource, and watch the pods and the log.
4. Run the checks. If they fail, decide: fix forward, or restore the dump and the old image together.
5. Record what happened and how long it took.

## What to keep as you go

Export the realm settings before and after, and compare them. An upgrade should change nothing in your configuration by itself, so any difference is worth a look. A diff of two exports takes a minute and catches a setting that moved.
