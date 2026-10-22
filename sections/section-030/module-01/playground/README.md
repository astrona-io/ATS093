# Put Keycloak Behind A Reverse Proxy — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-093-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox that spins up, installs the Keycloak Operator with the module's
starting resources, and stays running so you can explore. Nothing to submit.
Built from the Keycloak 26.8.1 documentation and not yet run.

## Run it

```sh
astrona run -c .
astrona destroy ats-093-playground-030-01
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Installs the operator and creates the starting resources |
| `manifests/` | Starting workloads and the module's Keycloak resources |
| `docs/overview.md` | What the environment contains and ideas to try |
