---
estimated_duration: 25m
---

# Restore Keycloak From A Database Dump

- **ID:** LAB
- **Slug:** ats-093-lab-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab in the namespace `keycloak`. Read `question.md` for the task; `solution.md` is the walkthrough. Built from the Keycloak 26.8.1 documentation and not yet run: check it with `astrona test` before relying on it.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-093-lab-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-093-lab-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Operator install and the starting state |
| `manifests/` | Starting workloads and resources applied by the bootstrap |
| `solution/` | Reference solution used by `astrona test` |
| `validation/` | Grading scripts, one per check |
