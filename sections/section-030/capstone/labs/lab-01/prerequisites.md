# Prerequisites

Before starting this capstone you should be able to:

- Use `percli login`, `percli project`, `percli apply -f` and `percli describe`.
- Read and write Perses resources in YAML.
- Write simple PromQL, LogQL and TraceQL queries.

## What the environment gives you

The environment builds itself before the task begins. It takes a few minutes:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, with authentication off, and
  `percli` 0.54.0 and Helm 3.22.1 in `/usr/local/bin` or `~/.local/bin`.
- The namespace `observability` with Prometheus, Loki behind a gateway with
  basic authentication, Tempo and Pyroscope, and telemetry for the services
  `checkout` and `payments` in the environments `production` and `staging`.
- The project `inventory` and the global datasources the task describes.

Start the port-forward in a second terminal and leave it running, then log
`percli` in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

If `perses.localtest.me` does not resolve on your machine, add the line
`127.0.0.1 perses.localtest.me` to `/etc/hosts`.

## Working rules

- Everything is graded on the **final state** of the Perses resources and on
  real queries through the Perses proxy.
- Change one resource at a time and check the result before the next change.
- Do not delete a resource the task asks you to repair.
