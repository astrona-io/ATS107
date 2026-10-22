# One Value In PromQL, LogQL And TraceQL

The environment and service the reader picks are just two strings, `production` and `payments`. Each backend, though, stores them under its own name and has its own syntax for comparing them. A unified dashboard only works if every query writes the two strings into the right place in its own language. This part goes through the three languages and tests each query with the values written in by hand.

## The same labels under three names

The telemetry generator sends two OpenTelemetry resource attributes with every metric, log line and span: `deployment.environment` and `service.name`. Each backend turns them into something it can query:

| Backend | Environment | Service | Selector syntax |
| --- | --- | --- | --- |
| Prometheus | `deployment_environment` | `service_name` | `metric{label="value"}` |
| Loki | `deployment_environment` | `service_name` | `{label="value"}` |
| Tempo | `resource.deployment.environment` | `resource.service.name` | `{resource.attribute="value"}` |

Prometheus and Loki replace the dots with underscores, because their label names cannot contain dots. Tempo keeps the dots and adds the level in front: `resource.` for an attribute of the program that sent the span. TraceQL joins conditions with `&&`; PromQL and LogQL join matchers with a comma.

## Three queries, one selection

Here are the three queries of an incident dashboard, with the variables where the values go:

| Panel | Query |
| --- | --- |
| Request rate | `sum by (service_name) (rate(app_requests_total{deployment_environment="$env", service_name="$service"}[5m]))` |
| Logs | `{deployment_environment="$env", service_name="$service"}` |
| Traces | `{resource.deployment.environment="$env" && resource.service.name="$service"}` |

Write `production` and `payments` in by hand and send each query through the proxy, exactly as the panels will. Start with the metrics:

<!-- astrona:playground:renew -->

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total{deployment_environment="production", service_name="payments"}[5m]))' \
  | jq '.data.result | length'
```

The answer is `1`: one series for `payments`. Then the logs:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/loki/loki/api/v1/query_range \
  --data-urlencode 'query={deployment_environment="production", service_name="payments"}' \
  | jq '.data.result | length'
```

The answer is at least `1`: the log streams of `payments` in `production`. Loki can split one service's lines into several streams when they differ in another index label. Then the traces:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/tempo/api/search \
  --data-urlencode 'q={resource.deployment.environment="production" && resource.service.name="payments"}' \
  | jq '.traces | length'
```

The answer is a number greater than zero, up to the search limit. All three panels will show data for this pair. Repeat the three calls with `staging` and `payments`, and all three answers drop to zero: that pair does not exist, which is why the cascade keeps it out of the service list.

## Where each query goes

Each query goes into its own panel, with the panel and query plugins for its signal:

| Panel plugin | Query kind | Query plugin |
| --- | --- | --- |
| `TimeSeriesChart` | `TimeSeriesQuery` | `PrometheusTimeSeriesQuery` |
| `LogsTable` | `LogQuery` | `LokiLogQuery` |
| `TraceTable` | `TraceQuery` | `TempoTraceQuery` |

None of the three queries needs a `datasource` field: each uses the default datasource of its kind. The two variables, `env` and then `service`, sit at the top of the dashboard, built as a cascade from Prometheus label values.

## When one panel stays empty

If two panels show data and the third is empty, the selection reached all three, and the third query names a label its backend does not have. The usual mistakes are `service` instead of `service_name` in LogQL, and `span.service.name` or a missing `resource.` in TraceQL. Write the values in by hand, send the query through the proxy, and change one label at a time until it returns data.

You can now write one selection into three query languages and prove every panel returns data. That is everything the incident dashboard needs.

## Common pitfalls

> [!WARNING]
> - **Dots in PromQL or LogQL.** `service.name` is not a valid label there; the name is `service_name`.
> - **The wrong level in TraceQL.** `span.service.name` looks at span attributes; the service name is a resource attribute.
> - **A comma in TraceQL.** Conditions inside one selector are joined with `&&`.
> - **A LogQL selector in single quotes but the YAML value not quoted.** A value that starts with `{` must be quoted in YAML.

## Your mission: Build A Unified Incident Dashboard

You can now build a cascade from environment to service and write the selection into PromQL, LogQL and TraceQL. The graded lab asks you to build the dashboard `incident` in the project `inventory` with the variables `env` and `service` as a cascade, and a metrics, a logs and a traces panel that all follow both.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-040-01
astrona start ats-107-playground-040-01
```
