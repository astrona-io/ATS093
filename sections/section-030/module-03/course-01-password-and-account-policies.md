# Password And Account Policies

Most account takeovers start with a password: a guessed one, a reused one, or one stolen from another site. A realm cannot stop users from making bad choices, but it can refuse the worst of them and make the rest harder to use.

## The password policy

A password policy is a single string in the realm settings. Rules are joined with `and`, and each rule has a name and, where needed, a value. The most used rules are:

| Rule | What it requires |
| --- | --- |
| `length(12)` | At least 12 characters |
| `notUsername` | The password is not the user name |
| `notEmail` | The password is not the email address |
| `digits(1)`, `upperCase(1)`, `lowerCase(1)`, `specialChars(1)` | At least that many of each kind |
| `passwordHistory(5)` | Not one of the last five passwords |
| `forceExpiredPasswordChange(90)` | A password older than 90 days must be changed |
| `passwordBlacklist(file)` | Not in a list of common passwords |
| `regexPattern(...)` | Matches a regular expression |

Current guidance puts length first. A long passphrase beats a short password with symbols, and forced rotation without a reason makes users choose predictable changes. Prefer `length`, a blacklist and `notUsername` over a long list of character classes. A policy applies when a password is set or changed, so existing passwords stay valid until their users change them.

Set it with the administration tool, then prove it by trying to break it:

```sh
kcadm update realms/inventory -s 'passwordPolicy=length(12) and notUsername'
kcadm set-password -r inventory --username bob --new-password 'Short1'
```

The second command must fail. A rule you have not seen refuse something is a rule you do not know works.

## Hashing is slow on purpose

Keycloak stores a hash of each password, never the password. The hash function is made expensive so that an attacker with a stolen database cannot test billions of guesses. The default in current versions is Argon2; the older option, PBKDF2, takes a number of iterations. Higher cost means a stronger hash and more CPU on every sign-in. Under a login storm the hashing is where the CPU goes. Do not lower the cost to make tests faster in production; raise the number of pods instead.

## Second factors

A second factor turns a stolen password into a failed attempt. Keycloak supports one-time passwords, WebAuthn security keys and passkeys. Make them required through the authentication flow, not only available: a factor that users may skip protects the users who needed it least. Require it for administrators first. For the others, use the required action **Configure OTP** so users are asked at the next sign-in.

## Brute force and required actions

Brute force detection limits guessing against one account, and rate limiting at the proxy limits it against all accounts. Required actions force a step at the next sign-in: update password, verify email, configure OTP. Use them to roll out a new policy to users who already exist.

## Try it

In the playground, compare a password change before and after the policy:

```sh
kcadm_login
kcadm get realms/inventory --fields passwordPolicy
kcadm set-password -r inventory --username bob --new-password 'Short1' && echo "accepted"
kcadm update realms/inventory -s 'passwordPolicy=length(12) and notUsername'
kcadm set-password -r inventory --username bob --new-password 'Short1' || echo "refused"
```

The first attempt is accepted and the second is refused. Put back the original password afterwards with `bob-password`, which is 12 characters or more.
