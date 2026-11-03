# Query Results As Variable Values

A list of label values shows every service that ever had a series. Sometimes the list should depend on what is happening now: only services with traffic, or only the busiest three. A `PrometheusPromQLVariable` fills a list from a PromQL expression. This part builds one, and then gives the steps to follow when any variable list is empty or wrong.

## A list from an expression

The plugin takes an `expr`, the PromQL expression to run, and a `labelName`, the label of the result whose values become the list. Save this as `dashboard-busy.yaml`:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: busy
  project: inventory
spec:
  display:
    name: Busy
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: busy
        display:
          name: Busy services
          hidden: false
        allowAllValue: true
        allowMultiple: true
        plugin:
          kind: PrometheusPromQLVariable
          spec:
            expr: topk(2, sum by (service_name) (rate(app_requests_total[5m])))
            labelName: service_name
  panels:
    requests:
      kind: Panel
      spec:
        display:
          name: Requests per second of the busy services
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
                  query: sum by (service_name) (rate(app_requests_total{service_name=~"$busy"}[$__rate_interval]))
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

Apply it with `percli apply -f dashboard-busy.yaml`. The dropdown `Busy services` lists the two services with the highest rate at the moment you open the dashboard. The expression runs as an instant query at the current time, so the list can change between two visits, and the selected values are not saved with the dashboard.

## When the list is empty or wrong

Follow these steps in order. Each one rules out one cause.

1. **Run the expression by hand.** Send it through the proxy and count the series. The window must be a fixed value, as built-in variables are not defined outside a dashboard:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=topk(2, sum by (service_name) (rate(app_requests_total[5m])))' | jq '.data.result | length'
```

2. **Check the label.** The `labelName` must be a label that the result still has. After `sum by (service_name)`, only `service_name` is left. A `labelName` of `deployment_environment` on that expression gives an empty list.
3. **Check the datasource.** A variable without a `datasource` field uses the default datasource of its kind. If the dashboard should use another datasource, set `datasource` in the variable spec, or point it at a datasource variable.
4. **Check the order.** A variable that uses another variable must come after it in `spec.variables`.
5. **Check the use.** The query must use the same name, `$busy`, and `=~` when the variable allows several values.

## Pick the source for the question

| The list should hold | Use |
| --- | --- |
| Values you choose by hand | `StaticListVariable` |
| Every value of a label | `PrometheusLabelValuesVariable` |
| Every label name | `PrometheusLabelNamesVariable` |
| Values that depend on current data | `PrometheusPromQLVariable` |

## Common pitfalls

> [!WARNING]
> - **An expression that loses the label.** `sum(...)` without `by` returns no labels, so the list is empty.
> - **Expecting a stable list.** A list built from `topk` changes with the data. Do not write tests or links that depend on a given order.
> - **`$__range` in a variable expression you test with `curl`.** The proxy sends the text to Prometheus unchanged. Replace the variable with a duration first.
