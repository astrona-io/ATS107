# Built-In Variables

Perses defines a set of variables in every dashboard. You do not add them to `spec.variables`, and they do not appear as dropdowns. A query uses them with the same `$name` syntax as any other variable.

## The list

| Variable | What it holds |
| --- | --- |
| `$__interval` | The step of the chart: the distance between two points of a range query, as a duration such as `30s` |
| `$__interval_ms` | The same step in milliseconds |
| `$__range` | The length of the dashboard time range as a duration, for example `6h` |
| `$__range_s` | The length of the time range in seconds |
| `$__range_ms` | The length of the time range in milliseconds |
| `$__rate_interval` | A window for `rate`, computed from the step and the scrape interval of the datasource |
| `$__project` | The name of the project of the open dashboard |
| `$__dashboard` | The name of the open dashboard |

Perses picks the step from the length of the time range and the width of the panel, so a wide chart on a short range has a small step and a narrow chart on a long range has a large one. A query can set a lower bound with `minStep`, and the step is never smaller than that.

The values change when the reader changes the time picker, and for `$__interval` also when the panel is resized. A built-in variable is therefore the right tool for any number that must follow the window.

## A stat that follows the window

A stat chart can answer "how many requests arrived in the window the reader picked". The function `increase` returns how much a counter grew over a range, and `$__range` is the range. Save this as `dashboard-windows.yaml`:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: windows
  project: inventory
spec:
  display:
    name: Windows
  duration: 1h
  panels:
    total:
      kind: Panel
      spec:
        display:
          name: Requests in the window
        plugin:
          kind: StatChart
          spec:
            calculation: last
            format:
              unit: decimal
              decimalPlaces: 0
              shortValues: true
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum(increase(app_requests_total[$__range]))
    smooth:
      kind: Panel
      spec:
        display:
          name: Requests per second, averaged over each step
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
                  query: sum(rate(app_requests_total[$__interval]))
                  minStep: 1m
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
            width: 16
            height: 6
            content:
              $ref: "#/spec/panels/smooth"
```

Apply it with `percli apply -f dashboard-windows.yaml` and open `http://perses.localtest.me:8080/projects/inventory/dashboards/windows`. Change the time picker from 1 hour to 6 hours and the stat grows, because the range grew. The second panel uses `$__interval` as its window, so each point averages exactly one step; the `minStep` of one minute keeps the step from falling below the scrape rhythm of the data.

## Where built-in variables are not defined

Built-in variables are filled in by the dashboard when a panel runs its query. They exist in panel queries and in the variables of the dashboard. A query you send with `curl` through the proxy has no dashboard around it, so `$__range` is sent as plain text and the backend answers with a parse error. When you test a query by hand, replace the built-in variable with a real value first, such as `1h` for `$__range`.

## Common pitfalls

> [!WARNING]
> - **Testing a query with `curl` while it still contains `$__range`.** The backend does not know the name. Replace it with a duration first.
> - **Using `$__interval` as the window of `rate`.** On a short range the step can be shorter than two scrapes, and `rate` then returns nothing. The next part explains the safer variable.
> - **Reading `$__range` as a time, not a length.** It is a duration such as `6h`, not a start time.
