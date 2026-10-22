# Show Metrics, Logs, Traces And Profiles

A dashboard with only metrics tells you that the error rate of `checkout` went up. It does not tell you which error, which request or which function. Perses can put the logs, the traces and the profiles of the same service next to the metrics, so the next question is one glance away. Each signal comes from a different backend and needs a different kind of panel.

This module builds a dashboard with one panel per signal. Keep one sentence in mind: **a panel plugin draws, a query plugin fetches, and the two must belong to the same kind of data.** A `TimeSeriesChart` draws `TimeSeriesQuery` results, a `LogsTable` draws `LogQuery` results, a `TraceTable` draws `TraceQuery` results and a `FlameChart` draws `ProfileQuery` results.

The module has three parts. **Metrics Panels And The Dashboard Model** builds the first panel and takes the dashboard resource apart. **Logs From Loki** adds a log table and a log rate. **Traces From Tempo And Profiles From Pyroscope** adds a trace table and a flame graph, and ends with a graded lab.

## Learning objectives

After this module you can:

- Read and write the `panels`, `queries` and `layouts` of a dashboard resource.
- Show a PromQL query as a time series.
- Show a LogQL query as a log table and as a log rate.
- Show a TraceQL search as a trace table, and name the panels for one trace and for trace durations.
- Show a Pyroscope profile as a flame graph.
- Run any panel's query through the Perses proxy to tell an empty query from a broken panel.

## Before you start

You need the Perses resource format and `percli apply`, and you need to read PromQL. LogQL and TraceQL are explained as far as this module needs them.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses` and the backends in the namespace `observability`:

| Workload | What it holds |
| --- | --- |
| `prometheus` | The counter `app_requests_total` with the labels `service_name` and `deployment_environment` |
| `loki` | The log lines of the same services, with the same labels |
| `tempo` | The traces of the same services; the labels are the resource attributes `service.name` and `deployment.environment` |
| `pyroscope` | CPU and memory profiles of Pyroscope itself, under the service name `pyroscope` |

Telemetry arrives for `checkout` in `production` and `staging`, and for `payments` in `production`. Perses holds the project `inventory` and a default global datasource for each backend: `prometheus`, `loki`, `tempo` and `pyroscope`. Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
