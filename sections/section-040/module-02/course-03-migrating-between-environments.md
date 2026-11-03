# Migrating Between Environments

A realm moves from development to test to production. If the same file goes through all three, what must differ between them, and where does the difference live?

## What differs

| Difference | Why | Where to keep it |
| --- | --- | --- |
| Hostnames in redirect URIs and web origins | Each environment has its own address | A value per environment in the template |
| Client secrets | A secret shared across environments is a leak in one of them | A Secret per environment, filled in through placeholders |
| Users and passwords | Production people are not test people | Not in the file; created or federated |
| Mail server and identity provider settings | Test must not send real mail | Realm settings per environment |
| Signing keys | Each realm generates its own | Generated on import, or provided as a key provider |

The file carries the structure, and the environment carries the values. A template with placeholders, and a short list of values per environment, is easier to review than three copies of the same JSON that slowly drift apart.

## Keys

A realm signs tokens with keys that are generated when the realm is created. The private key is a secret and is masked in a partial export, so an imported realm gets a new key unless you provide one. Applications that read the public keys from the `jwks_uri` of the realm follow the change on their own. Applications that copied a public key into their configuration break on the first token. Check for these before a cutover.

## The import does not update

Because an import creates a realm only when it does not exist, a second import of a changed file does nothing. This surprises teams who treat the file as the source of truth. They have three honest choices:

1. **Create once, then manage the live realm.** Use the file to bootstrap, then use the console, the administration tool or another configuration tool for changes. Export again to record them.
2. **Rebuild on change.** In environments without real users, delete the realm and import the new file. This works for test and review environments and never for production.
3. **Apply changes with a tool.** Use `kcadm.sh` or a configuration-as-code tool that updates the objects in a realm one by one.

Choose one for each environment and write it down. The worst case is two: a file in Git that no one imports, and a live realm that no one exports.

## Users

Users are data, not configuration. Moving production users into test copies personal data into a place with weaker controls. When a test needs users, create a few with known passwords in the import, as the playground does for `alice` and `bob`. When a real migration needs the people, use the offline export with its users, move it over a protected channel, and delete the files afterwards.

## Cutover

A migration to a new server is a plan with a rollback:

1. Export or dump from the old server and import into the new one.
2. Test sign-in with a test user and one client, on the new address.
3. Lower the DNS lifetime ahead of time, then switch the address.
4. Keep the old server and its data until you have checked the first day of traffic.

Sessions do not travel with an export. Users sign in again after a cutover, which is a reason to do it at a quiet time.
