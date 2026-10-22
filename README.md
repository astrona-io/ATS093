# ATS093 — Production Operations, Security & Kubernetes (Keycloak)

Course material for the **Production Operations, Security & Kubernetes**
domain of the Astrona Keycloak training path
([ATP018](https://github.com/astrona-io/ATP018)), which is **15% of the path**.
Written for the **Keycloak Operator 26.8.1** and **Keycloak 26.8.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Keycloak 26.8.1 documentation and the 26.8.1 custom resource
> definitions. None has been started on a cluster, and no lab has passed
> `astrona test` yet. See `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and graded **labs**, each placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's module into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Running Keycloak With The Keycloak Operator | 1 | 1 + capstone | The Keycloak Operator |
| [020](sections/section-020) | Databases And Clustering | 1 | 1 + capstone | Database and clustering |
| [030](sections/section-030) | Edge Security | 1 | 2 + capstone | TLS termination, exposure, brute force, rate limiting |
| [040](sections/section-040) | Backup, Restore And Upgrades | 1 | 1 + capstone | Backup, restore and upgrades |

The order follows a deployment's life. Section 010 brings Keycloak up through
the operator. Section 020 makes it highly available. Section 030 opens it to
the outside world safely. Section 040 keeps its data safe through failures and
upgrades.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Deploy Keycloak With The Operator](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Run Keycloak As A Cluster](sections/section-020/module-01/course.md) | 2 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Put Keycloak Behind A Reverse Proxy](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01), [lab-02](sections/section-030/module-01/labs/lab-02) |
| 040-01 | [Back Up, Restore And Upgrade Keycloak](sections/section-040/module-01/course.md) | 3 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Deploy Keycloak And Its Realm With The Operator | nothing deployed yet: write the `Keycloak` resource and a realm import with placeholders |
| [020](sections/section-020/capstone/labs/lab-01) | Keep Sessions Alive Through A Pod Restart | one instance, `cache=local`, a memory request no node can give |
| [030](sections/section-030/capstone/labs/lab-01) | Harden The Keycloak Edge | internal hostname, no proxy headers, `/admin/` and `/metrics` public, no lockout, no rate limit |
| [040](sections/section-040/capstone/labs/lab-01) | Recover After A Failed Upgrade | an image tag that does not exist under `RecreateOnImageChange`, a realm lost after the last dump |

---

## The lab environment

Every playground and lab is a **kind** cluster with everything in the namespace
`keycloak`: the Keycloak Operator 26.8.1 (installed from the
`keycloak-k8s-resources` 26.8.1 manifests), PostgreSQL 17, the Secrets
`keycloak-db` and `inventory-secrets`, a `tester` pod, and in section 030 an
nginx reverse proxy with a self-signed certificate. Two Keycloak pods,
PostgreSQL and the operator need about 6 GiB of memory.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS093.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks, and several of
them deliberately reject the plausible-but-wrong fix (a database password in
`additionalOptions`, `cache=local`, switching off the operator's network
policy, a permanent lockout, restoring over the damaged database).
