# The Rate Interval

Every example in this course so far wrote `rate(app_requests_total[5m])`. The `5m` is a number that depends on the window, and it is right only for some windows. This part shows when it fails and what `$__rate_interval` does about it.

## What the range selector does

`rate(metric[W])` takes the samples of the last `W` before each point and computes the average growth per second. Prometheus needs at least two samples inside `W` to compute a rate. If the data is scraped every minute and `W` is `30s`, most windows hold one sample or none, and the query returns no points.

The window also decides how smooth the line is. A short `W` follows every change and looks noisy. A long `W` hides short spikes. On a chart of six hours with 500 points, one point is about 43 seconds, and a `W` of `5m` overlaps the windows of about seven neighbouring points, which is fine. On a chart of seven days, one point is about 20 minutes, and a `W` of `5m` looks at one quarter of the time between two points and ignores the rest, so a spike between two points is never seen.

## What `$__rate_interval` is

`$__rate_interval` is a window computed to avoid both problems. It is never shorter than four times the scrape interval of the datasource, so a rate always has samples to work with, and it grows with the step of the chart, so the windows of neighbouring points cover the time between them. You set the scrape interval on the datasource with `scrapeInterval`, and Perses reads it from there.

## Compare the two

Save this as `dashboard-windows.yaml`, replacing the earlier file. It draws the same rate with a fixed window and with the rate interval:

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
    fixed:
      kind: Panel
      spec:
        display:
          name: Fixed window of 5 minutes
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
                  query: sum(rate(app_requests_total[5m]))
    adaptive:
      kind: Panel
      spec:
        display:
          name: Rate interval
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
                  query: sum(rate(app_requests_total[$__rate_interval]))
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 12
            height: 8
            content:
              $ref: "#/spec/panels/fixed"
          - x: 12
            y: 0
            width: 12
            height: 8
            content:
              $ref: "#/spec/panels/adaptive"
```

Apply it with `percli apply -f dashboard-windows.yaml`, open the dashboard and try three windows with the time picker: the last 15 minutes, the last hour and the last 6 hours. On the short window the left panel is smooth and the right panel follows the data more closely. On the long window both look alike, because the rate interval has grown towards the step.

## Why the grader and your tests use a fixed value

`$__rate_interval` exists only inside a dashboard. When you test the same query with `curl`, replace it with a fixed window that is longer than two scrapes, such as `5m`:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum(rate(app_requests_total[5m]))' | jq '.data.result | length'
```

A count above zero proves the metric and the label exist. The window only changes the numbers.

## Which one to choose

Use `$__rate_interval` inside `rate`, `irate` and `increase` on counters that you chart over time. Use `$__interval` in functions such as `avg_over_time` and `max_over_time`, where one point should summarise exactly one step. Use `$__range` when the answer is one number for the whole window. Keep a fixed window when the window is the question, such as "the rate over the last five minutes" on an alert-style stat.

## Common pitfalls

> [!WARNING]
> - **A fixed `[1m]` window with a datasource that scrapes every minute.** Many windows hold fewer than two samples, so the chart has gaps. Use `$__rate_interval`.
> - **A wrong `scrapeInterval` on the datasource.** The rate interval is computed from it. A value much larger than the real interval makes the chart too smooth; a smaller one brings the gaps back.
> - **Mixing `$__rate_interval` with `irate`.** `irate` uses only the last two samples inside the window, so a longer window does not smooth it.
