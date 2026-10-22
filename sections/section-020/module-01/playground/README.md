# Show Metrics, Logs, Traces And Profiles — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-107-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Perses, the observability stack, the project inventory and a default global datasource for each signal. Nothing to submit. Built from the Perses v0.54.0 documentation
and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-107-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-107-playground-020-01`), not
the config path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Helm, percli, CoreDNS rewrite, the stack, Perses and its starting resources |
| `manifests/perses-values.yaml` | Helm values for Perses |
| `manifests/lab-start.yaml` | The observability stack |
| `manifests/perses/` | Perses resources applied at start |
| `docs/overview.md` | What the environment contains and ideas to try |
