---
estimated_duration: 35m
---

# Build A Unified Incident Dashboard

- **ID:** LAB
- **Slug:** ats-107-lab-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab on Perses v0.54.0 in project `inventory`. Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the Perses v0.54.0 documentation and plugin schemas and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-107-lab-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-107-lab-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-perses.sh` | Helm, percli, the CoreDNS rewrite, the stack, Perses and its starting resources |
| `bootstrap/02-seed-state.sh` | The starting state of the task |
| `manifests/` | Perses Helm values, the stack, base resources (`perses/`) and the starting state (`seed/`) |
| `solution/` | Reference solution used by `astrona test` |
| `testing/wait-for-perses.sh` | Waits until Perses and the telemetry are ready |
| `validation/` | Grading scripts, one per check |
