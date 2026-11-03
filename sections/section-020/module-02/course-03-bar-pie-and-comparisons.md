# Bar Charts, Pie Charts And Tables

A stat chart shows one number and a gauge shows one number against a limit. Often you need to compare the same number across several things: the request rate of each service, the share of each status code. One panel per service does not scale, so Perses has panels that draw one value for each series in the same chart. This part builds a `BarChart`, describes the `PieChart`, and ends with the graded lab.

## One bar for each series

A `BarChart` reduces each series to one value with the `calculation`, as a stat chart does, and then draws one bar per series. The query must therefore return several series, one for each thing you compare. A PromQL `sum by (service_name)` does that: it returns one series for `checkout` and one for `payments`.

The bar chart has these settings:

| Field | What it does |
| --- | --- |
| `calculation` | Which point or combination of points becomes the bar's value |
| `format` | The unit and the decimal places, as for a stat chart |
| `sort` | `asc` or `desc` order of the bars by value |
| `mode` | `value` draws the number itself, `percentage` draws each bar as a share of the total |

Add this panel to the `panels` map of the dashboard `numbers`, and an item for it to the grid:

<!-- astrona:playground:renew -->

```yaml
    by-service:
      kind: Panel
      spec:
        display:
          name: Requests per second by service
        plugin:
          kind: BarChart
          spec:
            calculation: last
            sort: desc
            mode: value
            format:
              unit: requests/sec
              decimalPlaces: 2
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (service_name) (rate(app_requests_total[5m]))
                  seriesNameFormat: "{{service_name}}"
```

The field `seriesNameFormat` sets the text of each bar's label. The text `{{service_name}}` is replaced by the value of the label `service_name`, so the bars are named `checkout` and `payments` instead of the full label set.

The grid item for the panel, placed under the two others:

```yaml
          - x: 0
            y: 6
            width: 16
            height: 8
            content:
              $ref: "#/spec/panels/by-service"
```

Apply the file again with `percli apply -f dashboard-numbers.yaml`, and reload the dashboard. The panel shows two bars. Change `mode` to `percentage` and reload: the bars now show the share of each service in the total instead of the rate.

## Pie charts

A `PieChart` answers the same question as a `BarChart` in mode `percentage`: how large is each part of the whole. It takes a `calculation`, a `format`, a `sort`, a `mode` and a `legend` with a `position` (`bottom` or `right`). A pie is easy to read with two or three slices and hard to read with ten, so prefer the bar chart when the series count can grow.

## When to use which panel

| Question | Panel |
| --- | --- |
| What is the value now? | `StatChart` |
| How close is the value to a limit? | `GaugeChart` |
| Which series has the highest value? | `BarChart` |
| How do the parts divide a whole, with few parts? | `PieChart` |
| How did the value change over time? | `TimeSeriesChart` |

With the three panel kinds and the shared settings, you can answer most operational questions on one screen. What remains is to build a complete dashboard and prove that every query returns data.

## Common pitfalls

> [!WARNING]
> - **A bar chart on a query that returns one series.** The chart shows one bar. Add `sum by (...)` to return one series for each thing you compare.
> - **Leaving out `seriesNameFormat`.** The bar labels are the full label set, which is long and hard to read.
> - **Comparing counters without `rate`.** A raw counter only grows, so the bars show how long each service has run, not how busy it is.

## Your mission: Build A Numbers Dashboard

You can now build a stat chart, a gauge and a bar chart and set their calculation, unit and thresholds. The graded lab asks you to build a dashboard of the three panels for the project `inventory`, with the units and thresholds the task names, and to prove that every query returns data.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-020-02
astrona start ats-107-playground-020-02
```
