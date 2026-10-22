# Traces From Tempo And Profiles From Pyroscope

Metrics and logs tell you that `checkout` is slow and what it reported. A **trace** shows one request's path through the services, with the time each step took. A **profile** shows which functions of a program used the CPU or the memory. Both answer the "where" question, at two different levels. This part adds a trace table and a flame graph to a dashboard.

## TraceQL in one line

A trace is made of **spans**: one span per operation, with a start, a duration and attributes. Attributes live at two levels. Resource attributes describe the program that sent the span, for example `service.name`; span attributes describe the single operation. TraceQL, Tempo's query language, selects spans with conditions in curly braces and names the level in front of the attribute: `{resource.service.name="checkout"}` finds traces with spans from `checkout`.

Tempo keeps the dots of the OpenTelemetry names, so the label you know as `service_name` in Prometheus and Loki is `resource.service.name` here. Check that the search finds traces, through the default global `tempo` datasource:

<!-- astrona:playground:renew -->

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/tempo/api/search \
  --data-urlencode 'q={resource.service.name="checkout"}' --data-urlencode 'limit=5' \
  | jq -r '.traces[] | "\(.rootServiceName) \(.durationMs)"'
```

The answer lists up to five traces with their root service and duration in milliseconds.

## Three panels for traces

Perses has three panels for trace data, for three questions:

| Panel plugin | Question it answers | Query |
| --- | --- | --- |
| `TraceTable` | Which traces match? | A TraceQL search |
| `ScatterChart` | How long did the matching traces take, over time? | A TraceQL search |
| `TracingGanttChart` | What happened inside one trace? | One trace ID |

All three use the query plugin `TempoTraceQuery`, of kind `TraceQuery`. Its spec has the `query` and an optional `limit` on the number of traces.

## Profiles and flame graphs

Pyroscope stores **profiles**: samples of where a program spends its CPU time or its memory, collected many times per second. A **flame graph** draws a profile as stacked bars. Each bar is a function, its width is its share of the samples, and the functions it calls sit on top of it. The Pyroscope server in the playground profiles itself, under the service name `pyroscope`. Check that the datasource answers with the profile types it knows:

```sh
curl -s -X POST -H 'Content-Type: application/json' -d '{}' \
  http://perses.localtest.me:8080/proxy/globaldatasources/pyroscope/querier.v1.QuerierService/ProfileTypes \
  | jq -r '.profileTypes[].ID'
```

The answer lists IDs such as `process_cpu:cpu:nanoseconds:cpu:nanoseconds`. An ID names what was sampled and its unit. The query plugin `PyroscopeProfileQuery`, of kind `ProfileQuery`, takes one of these IDs as `profileType`, plus a `service`, and optional label `filters` and `maxNodes`.

## A dashboard with both

Save this as `dashboard-where-demo.yaml`:

```yaml
kind: Dashboard
metadata:
  name: where-demo
  project: inventory
spec:
  display:
    name: Traces and profiles demo
  duration: 1h
  panels:
    traces:
      kind: Panel
      spec:
        display:
          name: Checkout traces
        plugin:
          kind: TraceTable
          spec: {}
        queries:
          - kind: TraceQuery
            spec:
              plugin:
                kind: TempoTraceQuery
                spec:
                  query: '{resource.service.name="checkout"}'
                  limit: 20
    profile:
      kind: Panel
      spec:
        display:
          name: Pyroscope CPU
        plugin:
          kind: FlameChart
          spec:
            palette: package-name
            showSettings: true
            showSeries: false
            showTable: true
            showFlameGraph: true
        queries:
          - kind: ProfileQuery
            spec:
              plugin:
                kind: PyroscopeProfileQuery
                spec:
                  profileType: process_cpu:cpu:nanoseconds:cpu:nanoseconds
                  service: pyroscope
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 12
            height: 10
            content:
              $ref: "#/spec/panels/traces"
          - x: 12
            y: 0
            width: 12
            height: 10
            content:
              $ref: "#/spec/panels/profile"
```

Apply it:

```sh
percli apply -f dashboard-where-demo.yaml
```

Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/where-demo`. The trace table lists the matching traces; the flame graph shows where the Pyroscope server spends its CPU. Unlike the other panels, `FlameChart` has required fields: `palette`, `showSettings`, `showSeries`, `showTable` and `showFlameGraph`. Leave one out and `percli apply` fails, because Perses checks the panel spec against the plugin's schema.

## The four signals side by side

Every panel in this module followed the same pattern; only the plugins changed:

| Signal | Panel plugin | Query kind | Query plugin |
| --- | --- | --- | --- |
| Metrics | `TimeSeriesChart` | `TimeSeriesQuery` | `PrometheusTimeSeriesQuery` |
| Logs | `LogsTable` | `LogQuery` | `LokiLogQuery` |
| Traces | `TraceTable` | `TraceQuery` | `TempoTraceQuery` |
| Profiles | `FlameChart` | `ProfileQuery` | `PyroscopeProfileQuery` |

You can now put all four signals on one dashboard, and test each query through the proxy before you trust the panel.

## Common pitfalls

> [!WARNING]
> - **`service.name` without the level.** TraceQL needs `resource.service.name` for a resource attribute; `span.service.name` looks at the span level and finds nothing here.
> - **A trace ID in a `TraceTable`.** The table wants a search; one trace ID belongs in a `TracingGanttChart`.
> - **A `FlameChart` without its required fields.** `percli apply` refuses it and names the missing field.
> - **A profile type the service does not have.** Check the IDs with the `ProfileTypes` call first.

## Your mission: Build A Dashboard For Four Signals

You can now build a panel for each signal and prove its query returns data. The graded lab asks you to build the dashboard `signals` in the project `inventory` with one panel for metrics, logs, traces and profiles, all placed in the layout and all returning data.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-020-01
astrona start ats-107-playground-020-01
```
