# Variables That Choose A Grouping

A panel that shows `sum by (service_name) (...)` answers one question. The same panel with `sum by (deployment_environment) (...)` answers another, and a dashboard that needs both has two panels that differ in one word. A variable can hold that word. This part builds a group-by selector with a `StaticListVariable`, extends it to several labels, and shows the variable that reads label names from Prometheus.

## A group-by selector

A `StaticListVariable` takes `values`. Each entry is either a plain string or an object with a `value` and a `label`. The `label` is what the dropdown shows, and the `value` is what the query receives. A reader sees `Service` and the query receives `service_name`.

Save this as `dashboard-grouped.yaml`:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: grouped
  project: inventory
spec:
  display:
    name: Grouped
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: groupby
        display:
          name: Group by
          hidden: false
        allowAllValue: false
        allowMultiple: false
        defaultValue: service_name
        plugin:
          kind: StaticListVariable
          spec:
            values:
              - value: service_name
                label: Service
              - value: deployment_environment
                label: Environment
  panels:
    requests:
      kind: Panel
      spec:
        display:
          name: Requests per second
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              position: bottom
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by ($groupby) (rate(app_requests_total[$__rate_interval]))
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

Apply it with `percli apply -f dashboard-grouped.yaml` and open `http://perses.localtest.me:8080/projects/inventory/dashboards/grouped`. The dropdown `Group by` offers `Service` and `Environment`. With `Service` the chart has two lines, `checkout` and `payments`. Switch to `Environment` and it has two lines again, `production` and `staging`.

## Several labels at once

To group by both labels, set `allowMultiple: true`. The query then receives two values, and the default format would write them as `(service_name|deployment_environment)`, which is not valid in a `by` list. A `by` list needs commas, so use the `csv` format:

```yaml
                  query: sum by (${groupby:csv}) (rate(app_requests_total[$__rate_interval]))
```

The result is `sum by (service_name,deployment_environment) (...)`, and the chart has four lines, one for each pair. The syntax `${name:format}` is the same you used for other formats. With a single value, `$groupby` and `${groupby:csv}` give the same text, so the `csv` form is safe for both.

## Label names from Prometheus

When the labels of a metric change, a hand-written list goes out of date. A `PrometheusLabelNamesVariable` asks Prometheus for the label names instead. It takes optional `matchers`, series selectors that limit the answer to the labels of those series:

```yaml
        plugin:
          kind: PrometheusLabelNamesVariable
          spec:
            matchers:
              - app_requests_total
```

The list then holds every label name on `app_requests_total`. It also holds the name `__name__`, the label that stores the metric name, and labels that are not useful to group by. A hand-written list has only the choices you want the reader to have, so use a label names variable for exploration dashboards and a static list for dashboards others rely on.

## Your mission: Make A Rate Dashboard Adapt To Its Window

You can now use `$__rate_interval` in a `rate` and build a variable that chooses the grouping. The graded lab gives you a dashboard `rates` in the project `inventory` whose panel uses a fixed `[5m]` window and a fixed group-by label. You make it follow the window and let the reader choose the label.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-030-02
astrona start ats-107-playground-030-02
```

## Common pitfalls

> [!WARNING]
> - **A multi-value group-by variable without `:csv`.** The default format writes `(a|b)`, which `by` rejects.
> - **A `label` and a `value` swapped.** The query receives the `value`; if it holds the display name, the query groups by a label that does not exist.
> - **A group-by variable with `allowAllValue: true`.** The value `All` is not a label name, so the query fails. Keep it off.
