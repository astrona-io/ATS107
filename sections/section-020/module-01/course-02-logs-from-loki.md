# Logs From Loki

A rising request rate tells you something changed; a log line tells you what. Loki stores log lines and indexes them by labels, and Perses can show them in two ways: as the lines themselves, and as a count of lines over time. This part adds both to a dashboard and shows how to test a LogQL query through the proxy first.

## LogQL in two steps

LogQL is Loki's query language. Every LogQL query starts with a **stream selector**: labels in curly braces that pick the log streams, such as `{service_name="checkout"}`. A stream is all lines with the same set of labels. After the selector you can add **line filters**: `|= "order"` keeps lines that contain the text `order`, and `!= "debug"` drops lines that contain `debug`.

The telemetry generator sends its logs with the same labels as its metrics, so `service_name` and `deployment_environment` work here too. Check that the selector finds streams, through the default global `loki` datasource:

<!-- astrona:playground:renew -->

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/loki/loki/api/v1/query_range \
  --data-urlencode 'query={service_name="checkout"}' --data-urlencode 'limit=5' \
  | jq -r '.data.result[].stream.deployment_environment'
```

The answer lists `production` and `staging`: one stream for each environment `checkout` runs in. Loki's `query_range` endpoint returns the lines of the last hour when you give it no start and end.

## A log table

Lines go in a `LogsTable` panel, fed by a `LokiLogQuery`. The query kind is `LogQuery`. Save this as `dashboard-logs-demo.yaml`:

```yaml
kind: Dashboard
metadata:
  name: logs-demo
  project: inventory
spec:
  display:
    name: Logs demo
  duration: 1h
  panels:
    logs:
      kind: Panel
      spec:
        display:
          name: Checkout logs
        plugin:
          kind: LogsTable
          spec:
            showTime: true
        queries:
          - kind: LogQuery
            spec:
              plugin:
                kind: LokiLogQuery
                spec:
                  query: '{service_name="checkout"} |= "order"'
                  direction: backward
    log-rate:
      kind: Panel
      spec:
        display:
          name: Log lines per minute
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: LokiTimeSeriesQuery
                spec:
                  query: sum by (service_name) (count_over_time({service_name=~".+"}[1m]))
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 12
            height: 10
            content:
              $ref: "#/spec/panels/logs"
          - x: 12
            y: 0
            width: 12
            height: 10
            content:
              $ref: "#/spec/panels/log-rate"
```

Apply it:

```sh
percli apply -f dashboard-logs-demo.yaml
```

Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/logs-demo`. The left panel lists the newest `checkout` lines first, because `direction: backward` asks Loki for the newest lines first. The YAML quotes the query in single quotes because it starts with `{`, which YAML would read as the start of a map.

## A log rate

The right panel uses the same Loki datasource with a different query plugin. `count_over_time({...}[1m])` counts the lines of each stream per minute, and `sum by (service_name)` adds the streams of one service together. The result is a number over time, so the query plugin is `LokiTimeSeriesQuery`, the query kind is `TimeSeriesQuery`, and the panel is the same `TimeSeriesChart` that draws Prometheus data. One backend, two shapes of data, two query plugins.

| Query plugin | Query kind | Panel plugin | Shows |
| --- | --- | --- | --- |
| `LokiLogQuery` | `LogQuery` | `LogsTable` | The log lines |
| `LokiTimeSeriesQuery` | `TimeSeriesQuery` | `TimeSeriesChart` | A number per time step |

The `LogsTable` spec has a few optional switches: `showTime` adds the time column, `allowWrap` wraps long lines, and `enableDetails` lets the reader open one line to see all its labels. All three are optional; an empty `spec: {}` is valid.

## Other log backends

Loki is not the only log backend Perses supports. The release that this course uses also ships a **VictoriaLogs** plugin, with `VictoriaLogsDatasource`, `VictoriaLogsLogQuery` and `VictoriaLogsTimeSeriesQuery`, which fit the same `LogsTable` and `TimeSeriesChart` panels. The pattern stays the same: the panel plugin depends on the shape of the data, and the query plugin depends on the backend.

You can now show log lines and log counts next to your metrics. Traces and profiles are next, and they need two more panel plugins.

## Common pitfalls

> [!WARNING]
> - **An unquoted LogQL query in YAML.** A value that starts with `{` must be quoted, or YAML reads it as a map and `percli apply` fails.
> - **A selector without a label.** Loki needs at least one label matcher that is not empty; `{service_name=~".+"}` works, `{}` does not.
> - **A `LokiLogQuery` in a `TimeSeriesChart`.** Log lines are not a time series. Use `LokiTimeSeriesQuery` for counts.
> - **The wrong label name.** The OpenTelemetry attribute `service.name` becomes the Loki label `service_name`, with an underscore.
