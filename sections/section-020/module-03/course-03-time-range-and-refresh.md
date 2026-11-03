# Time Range And Refresh

Every chart on a dashboard answers the same question for one window of time. This part explains where that window comes from, how the dashboard refreshes it, how the reader and the URL change it, and how a query can use the window.

## The default window

The dashboard spec has two time fields:

| Field | What it sets |
| --- | --- |
| `duration` | How far back the window reaches from now, for example `1h`, `6h` or `7d` |
| `refreshInterval` | How often the panels run their queries again, for example `30s`; `0s` means never |

When a reader opens the dashboard, the window is the last `duration`, and the dashboard refreshes at the `refreshInterval`. Both are only defaults. The time picker in the dashboard header changes the window, and the refresh control changes the interval, for the reader's current view only.

## Set both on a dashboard

Save this as `dashboard-traffic.yaml`, replacing the earlier file. It has a six-hour default window and a refresh every 30 seconds:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: traffic
  project: inventory
spec:
  display:
    name: Traffic
  duration: 6h
  refreshInterval: 30s
  panels:
    rate:
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
                  query: sum by (service_name) (rate(app_requests_total[5m]))
                  seriesNameFormat: "{{service_name}}"
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/rate"
```

Apply it with `percli apply -f dashboard-traffic.yaml` and open the dashboard. The time picker shows the last 6 hours, and the refresh control shows 30 seconds.

## Change the window from the URL

The state of the picker is kept in the address of the page. Add `start` and `refresh` to the URL to open the dashboard with another window:

```text
http://perses.localtest.me:8080/projects/inventory/dashboards/traffic?start=15m&refresh=10s
```

The page opens with the last 15 minutes and a refresh every 10 seconds, without changing the dashboard. This is how you send a colleague a link to the exact window of an incident. For an absolute window, `start` and `end` take timestamps in milliseconds since the epoch.

## Use the window inside a query

A query that works for any window must not hard-code one. Perses gives every query the built-in variables `$__interval`, `$__range`, `$__rate_interval` and others; the next module explains them. A range selector such as `[5m]` in `rate(...)` is fixed. It is a sensible default for a six-hour window and gives a noisy line for a window of a week, because the same five minutes are used for points that are far apart.

## Common pitfalls

> [!WARNING]
> - **A very short `refreshInterval` on a long window.** Every panel runs its queries on each refresh, so a refresh every second on a week of data loads the backend for little gain.
> - **Editing the dashboard to share a window.** Share the URL with `start` instead; the dashboard keeps its default.
> - **Expecting `duration` to apply after the reader changed the picker.** The picker wins for that reader; the saved `duration` is only the starting point.
