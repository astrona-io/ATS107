# Solution: Build A Numbers Dashboard

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the dashboard `numbers` has a stat chart, a gauge and a bar chart with the right units, thresholds and sort order; every panel is placed in the layout; and every query returns data through the Perses proxy.

## Step 1: Connect percli

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Step 2: Test the three queries first

Each count must be greater than zero, and the last one must be at least two:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum(rate(app_requests_total[5m]))' | jq '.data.result | length'
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum(rate(app_requests_total{service_name="checkout"}[5m])) / sum(rate(app_requests_total[5m]))' | jq '.data.result | length'
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total[5m]))' | jq '.data.result | length'
```

## Step 3: Write and apply the dashboard

None of the queries names a datasource, so each uses the default `prometheus`. Save this as `dashboard-numbers.yaml`:

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
          - x: 0
            y: 6
            width: 16
            height: 8
            content:
              $ref: "#/spec/panels/by-service"
```

Apply it:

```sh
percli apply -f dashboard-numbers.yaml
```

Open `http://perses.localtest.me:8080/projects/inventory/dashboards/numbers` and check that all three panels show data.

## Step 4: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Use `percent` for the gauge | The query returns a value from 0 to 1, so the gauge shows a share of at most 1 percent |
| Use `sum(...)` without `by (service_name)` for the bar chart | The chart gets one series and draws one bar; the grader requires one series for each service |
| Leave a panel out of the layout | The panel exists but never appears on the dashboard |
