# Build A Unified Incident Dashboard

An alert says that `payments` in `production` fails. On a dashboard with separate metrics, logs and traces pages, the reader picks the service three times and may pick a different environment by mistake. On a unified dashboard, the reader picks the environment and the service once, and every panel follows. If the service list only offers services that run in the selected environment, the reader cannot pick a combination that does not exist.

This module builds that dashboard. Keep one sentence in mind: **a variable that uses another variable must come after it in the list, and every query must name the selected labels the way its own backend names them.** The first half is about variables, the second about query languages.

The module has two parts. **Variables That Depend On Other Variables** builds the cascade from environment to service and tests it. **One Value In PromQL, LogQL And TraceQL** writes the selection into a metrics, a logs and a traces panel, and ends with a graded lab.

## Learning objectives

After this module you can:

- Build a variable whose values depend on another variable through `$name` in its matchers.
- Order the variable list so every variable is known before another uses it.
- Name the environment and service labels correctly in PromQL, LogQL and TraceQL.
- Write one environment and service selection into a metrics, a logs and a traces query.
- Test a cascade and every panel by writing the values in by hand through the proxy.

## Before you start

You need to write a Perses dashboard with panels and layouts, to fill a list variable from Prometheus label values, and to read PromQL, LogQL and TraceQL selectors. You also need the rule that several selected values need `=~`.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses` and the backends in the namespace `observability`. All three signals carry the same environment and service information:

| Signal | Environment | Service |
| --- | --- | --- |
| Metrics (Prometheus) | label `deployment_environment` | label `service_name` |
| Logs (Loki) | label `deployment_environment` | label `service_name` |
| Traces (Tempo) | `resource.deployment.environment` | `resource.service.name` |

`checkout` runs in `production` and `staging`; `payments` runs in `production` only. Perses holds the project `inventory` and a default global datasource for each backend. Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
