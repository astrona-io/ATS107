# Connect Perses To Your Data Backends

A panel that shows nothing gives you no reason. The query can be right and the backend can be healthy, and the panel still stays empty, because the request never reached the backend. In Perses, that request always passes through a **datasource**: a resource that names a backend plugin, such as `PrometheusDatasource`, and says how the Perses server reaches it.

This module is about that resource. Keep one sentence in mind: **the dashboard picks a datasource by name and kind, and the Perses server forwards the query with that datasource's proxy settings and credentials.** Each part takes one piece of that sentence apart.

The module has three parts. **Datasources, Scopes And Overrides** shows the three places a datasource can live and how Perses chooses between them. **The Perses Proxy And Allowed Endpoints** follows one query through the Perses server to the backend and shows how to limit what it forwards. **Secrets For Datasource Credentials** gives a datasource the password its backend asks for, and ends with a graded lab.

## Learning objectives

After this module you can:

- Create a `GlobalDatasource` and a project `Datasource` with `percli apply`.
- Predict which datasource a query uses when several have the same name or when the query names none.
- Call a backend through the Perses proxy with `curl` and read the answer.
- Limit the proxy to the paths a plugin needs with `allowedEndpoints`, and prove other paths are refused.
- Store basic authentication credentials in a `Secret` and reference it from a datasource.
- Tell an error from the Perses server apart from an error from the backend.

## Before you start

You need Kubernetes basics (`kubectl get`, `kubectl port-forward`), the Perses resource format (`kind`, `metadata`, `spec`) and the `percli` commands `login`, `project`, `apply`, `get` and `describe`. You also need to read JSON with `jq`.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses`, with authentication off. The namespace `observability` runs the backends:

| Workload | What it is |
| --- | --- |
| `prometheus` | Prometheus 3.15.1 with the counter `app_requests_total` for the services `checkout` and `payments` |
| `loki` | Loki 3.7.9 with the logs of the same services |
| `loki-gateway` | An nginx proxy in front of Loki that asks for basic authentication; the lab-only user is `perses` with the password `loki-gateway-password` |
| `tempo` | Tempo 2.10.10 with the traces of the same services |
| `pyroscope` | Pyroscope 2.4.1, which profiles itself |

Perses already holds the project `inventory` and the global datasources `prometheus`, `loki`, `tempo` and `pyroscope`. The global `loki` datasource points at `loki-gateway` without credentials, on purpose. Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory` before you read on.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
