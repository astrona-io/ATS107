# Gauges And Thresholds

A single number tells you where you are. A gauge also tells you how far that is from the limit. When a value has a natural maximum, such as a share of 100 percent, a dial communicates the answer faster than the digits. This part adds a `GaugeChart`, explains the threshold modes, and shows the one setting that decides where the dial ends.

## The settings of a gauge

A `GaugeChart` has the same three shared settings as a stat chart: `calculation`, `format` and `thresholds`. It adds `max`, which is the end of the dial when the unit is not a percentage, and `legend.show`, which turns the label under the dial on or off.

When the unit is `percent`, the dial runs from 0 to 100. When the unit is `percent-decimal`, it runs from 0 to 1. For any other unit, the dial ends at `max`. A gauge on a unit such as `requests/sec` with no `max` has no meaningful end, so always set `max` for those.

## Share of traffic as a gauge

The ratio of the requests of `checkout` to all requests is a value between 0 and 1, so it fits `percent-decimal`. Save this as `dashboard-numbers.yaml`, replacing the earlier file. It keeps the stat panel and adds the gauge:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: numbers
  project: inventory
spec:
  display:
    name: Numbers
  duration: 1h
  panels:
    total:
      kind: Panel
      spec:
        display:
          name: Total requests per second
        plugin:
          kind: StatChart
          spec:
            calculation: last
            format:
              unit: requests/sec
              decimalPlaces: 2
            sparkline: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum(rate(app_requests_total[5m]))
    share:
      kind: Panel
      spec:
        display:
          name: Share of checkout
        plugin:
          kind: GaugeChart
          spec:
            calculation: last
            format:
              unit: percent-decimal
              decimalPlaces: 1
            thresholds:
              mode: absolute
              defaultColor: green
              steps:
                - value: 0.6
                  color: orange
                - value: 0.8
                  color: red
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum(rate(app_requests_total{service_name="checkout"}[5m])) / sum(rate(app_requests_total[5m]))
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 8
            height: 6
            content:
              $ref: "#/spec/panels/total"
          - x: 8
            y: 0
            width: 8
            height: 6
            content:
              $ref: "#/spec/panels/share"
```

Apply it:

```sh
percli apply -f dashboard-numbers.yaml
```

Before you trust the gauge, run the same query through the proxy and read the value yourself:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum(rate(app_requests_total{service_name="checkout"}[5m])) / sum(rate(app_requests_total[5m]))' \
  | jq -r '.data.result[0].value[1]'
```

The answer is a decimal number between 0 and 1. The gauge shows the same number as a percentage on a dial.

## Threshold modes

The `mode` of `thresholds` is `absolute` or `percent`. In `absolute` mode, each `value` is compared with the number as it is. In `percent` mode, each `value` is a percentage of the dial: with `max: 200`, a step with `value: 50` starts at 100. Use `absolute` when the limit is a fact of the system, such as a latency objective. Use `percent` when the limit is a fraction of a maximum that you set.

Change the gauge to the unit `requests/sec`, remove the division from the query, set `max: 20` and the mode `percent`, and give the steps the values `60` and `80`. The dial now turns orange at 12 requests per second and red at 16. Putting the same limits in `absolute` mode would need the values `12` and `16`.

You can now present one number as text and as a dial. When you need to compare several numbers at once, one panel per service is wasteful, and a bar chart does it in one panel.

## Common pitfalls

> [!WARNING]
> - **A gauge without `max` on a non-percent unit.** The dial has no end, so the position of the marker means nothing.
> - **Mixing up the modes.** `percent` thresholds are percentages of `max`, not percentages of the value.
> - **Dividing by zero in the query.** A ratio query returns no data when the denominator is zero, and the gauge stays empty.
