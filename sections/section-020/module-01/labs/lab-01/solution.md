# Solution: Build A Dashboard For Four Signals

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the dashboard `signals` has one panel with the matching query plugin for each signal, every panel is in the layout, and every panel's query returns data through the Perses proxy.

## Step 1: Connect percli

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Step 2: Test the four queries first

Before you write a panel, prove its query returns data through the default datasource of its kind. The counts must all be greater than zero:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total{service_name="checkout"}[5m]))' \
  | jq '.data.result | length'
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/loki/loki/api/v1/query_range \
  --data-urlencode 'query={service_name="checkout"}' | jq '.data.result | length'
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/tempo/api/search \
  --data-urlencode 'q={resource.service.name="checkout"}' | jq '.traces | length'
curl -s -X POST -H 'Content-Type: application/json' -d '{}' \
  http://perses.localtest.me:8080/proxy/globaldatasources/pyroscope/querier.v1.QuerierService/ProfileTypes \
  | jq '.profileTypes | length'
```

## Step 3: Write and apply the dashboard

None of the queries names a datasource, so each uses the default global datasource of its kind. Save this as `dashboard-signals.yaml`:

```yaml
kind: Dashboard
metadata:
  name: signals
  project: inventory
spec:
  display:
    name: Signals
  duration: 1h
  panels:
    requests:
      kind: Panel
      spec:
        display:
          name: Request rate
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (service_name) (rate(app_requests_total{service_name="checkout"}[5m]))
    logs:
      kind: Panel
      spec:
        display:
          name: Logs
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
                  query: '{service_name="checkout"}'
    traces:
      kind: Panel
      spec:
        display:
          name: Traces
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
          name: CPU profile
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
            height: 8
            content:
              $ref: "#/spec/panels/requests"
          - x: 12
            y: 0
            width: 12
            height: 8
            content:
              $ref: "#/spec/panels/logs"
          - x: 0
            y: 8
            width: 12
            height: 8
            content:
              $ref: "#/spec/panels/traces"
          - x: 12
            y: 8
            width: 12
            height: 8
            content:
              $ref: "#/spec/panels/profile"
```

Apply it:

```sh
percli apply -f dashboard-signals.yaml
```

If `percli apply` fails, the message names the field the plugin schema rejected. The most common cause is a `FlameChart` without one of its five required fields.

## Step 4: Check the result

List the panels and the query plugin of each:

```sh
percli describe dashboard signals -o json \
  | jq -r '.spec.panels | to_entries[] | "\(.key) \(.value.spec.plugin.kind) \(.value.spec.queries[0].spec.plugin.kind)"'
```

Each line pairs a panel plugin with its query plugin. Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/signals` and confirm all four panels show data.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Leave a panel out of the layout | The resource holds it, but the dashboard never shows it; the grader checks every `$ref` |
| Use `service.name` in PromQL | Prometheus has no such label; the panel stays empty |
| Use `span.service.name` in TraceQL | The attribute is on the resource, not the span; no traces match |
| Use a `TimeSeriesChart` for logs | A `LokiLogQuery` returns lines, not a time series |

## Practice on your own

- Add a log rate panel with `LokiTimeSeriesQuery` and `count_over_time`.
- Add a filter to the profile query and see how the flame graph changes.
