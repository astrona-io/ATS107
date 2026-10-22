# Variables Backed By Queries And Datasources

A static list of services is out of date the day a new service ships. The backend already knows every service: Prometheus has a `service_name` label on every series, and Loki has the same label on every stream. This part fills lists straight from the backends, and adds a variable that lets the reader choose which datasource the whole dashboard reads from.

## Values from label values

The most common source is the list of values a label has. Prometheus answers that question at `/api/v1/label/<label>/values`, and you can call it through the proxy. The optional `match[]` parameter limits the answer to series that match a selector:

<!-- astrona:playground:renew -->

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/label/service_name/values \
  --data-urlencode 'match[]=app_requests_total' | jq -r '.data[]'
```

The answer is `checkout` and `payments`. A `PrometheusLabelValuesVariable` makes the same call when the dashboard opens. Its spec has the `labelName`, an optional list of `matchers` (the `match[]` selectors), and an optional `datasource`. Without `matchers`, the list holds every value the label has on any series; with them, only values on matching series.

Loki has the same idea: a `LokiLabelValuesVariable` with `labelName` and `matchers` lists label values from log streams. The other Prometheus source is a `PrometheusPromQLVariable`. It runs a PromQL `expr` and takes the values of one `labelName` from the result. Use it when the list needs a calculation, for example only services with traffic in the last five minutes: `expr: sum by (service_name) (rate(app_requests_total[5m])) > 0`, `labelName: service_name`.

| Variable plugin | Where the values come from |
| --- | --- |
| `PrometheusLabelValuesVariable` | The values of one label on the series that match `matchers` |
| `PrometheusPromQLVariable` | The values of one label in the result of a PromQL expression |
| `LokiLabelValuesVariable` | The values of one label on the log streams that match `matchers` |
| `DatasourceVariable` | The names of the datasources of one kind |

## Choosing the datasource

The playground has two Prometheus datasources: the default `prometheus` and `prometheus-replica`. Many teams have the same situation with one Prometheus per region or per cluster. A `DatasourceVariable` lists the datasources of one kind, set in `datasourcePluginKind`, and the reader picks one. A query or another variable then names `$<variable>` in its `datasource` field instead of a fixed datasource. The schema of every Prometheus query and variable accepts either an object with `kind` and `name`, or a string `$name`.

Save this as `dashboard-datasource-demo.yaml`:

```yaml
kind: Dashboard
metadata:
  name: datasource-demo
  project: inventory
spec:
  display:
    name: Datasource demo
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: prometheus
        display:
          name: Prometheus
          hidden: false
        allowAllValue: false
        allowMultiple: false
        plugin:
          kind: DatasourceVariable
          spec:
            datasourcePluginKind: PrometheusDatasource
    - kind: ListVariable
      spec:
        name: env
        display:
          name: Environment
          hidden: false
        allowAllValue: false
        allowMultiple: false
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            datasource: $prometheus
            labelName: deployment_environment
            matchers:
              - app_requests_total
  panels:
    requests:
      kind: Panel
      spec:
        display:
          name: Requests in $env
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource: $prometheus
                  query: sum by (service_name) (rate(app_requests_total{deployment_environment="$env"}[5m]))
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/requests"
```

Apply it:

```sh
percli apply -f dashboard-datasource-demo.yaml
```

Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/datasource-demo`. The first dropdown lists `prometheus` and `prometheus-replica`. The second lists `production` and `staging`, read from whichever datasource is selected. Here both datasources reach the same Prometheus, so the data looks the same; in a real setup each choice shows a different region.

## Order matters

The `env` variable uses `$prometheus`, so Perses must know the value of `prometheus` before it can load the values of `env`. Perses resolves the variables in the order of the `variables` list, so a variable that another one uses comes first. When the reader changes the datasource, Perses loads the values of `env` again from the new one. This is the first case of variables that depend on other variables.

You can now fill lists from the backends and let the reader choose the datasource. What happens when the reader picks two services at once is still open: the next step is how several values are written into a query.

## Common pitfalls

> [!WARNING]
> - **A label values variable without matchers.** It lists the label's values on every series in Prometheus, including services that do not send the metric your panels use.
> - **A variable listed before the variable it uses.** Put the `DatasourceVariable` first.
> - **A query that keeps a fixed datasource.** The dropdown changes, the panel does not. Every query that should follow the choice needs `datasource: $prometheus`.
> - **A `DatasourceVariable` for the wrong kind.** `datasourcePluginKind` must name the datasource plugin, for example `PrometheusDatasource`, not `Prometheus`.

## Your mission: Add A Datasource Selector And A Service Variable

You can now build lists from label values and let the reader choose the datasource. The graded lab asks you to turn the dashboard `services`, which shows one hard-coded service, into one with a Prometheus datasource selector and a service variable that accepts several services at once.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-030-01
astrona start ats-107-playground-030-01
```
