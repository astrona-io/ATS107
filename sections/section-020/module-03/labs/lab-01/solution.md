# Solution: Tune A Traffic Dashboard

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the panel `rate` has the legend, axis, area and threshold settings; the panel `by-env` exists and is placed in a closed group titled `Details`; the dashboard has the right duration and refresh interval; and every query returns data, with the original panel still in the first layout.

## Step 1: Connect percli and export the dashboard

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

Export the dashboard so that you edit what is there:

```sh
percli get dashboard traffic -o yaml > dashboard-traffic.yaml
```

## Step 2: Test the second query first

The count must be 2, one series for each environment:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (deployment_environment) (rate(app_requests_total[5m]))' | jq '.data.result | length'
```

## Step 3: Edit the file

Change the dashboard spec in `dashboard-traffic.yaml` to this. Keep the `metadata` block the server wrote:

```yaml
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
              position: right
              mode: table
              values:
                - last
                - max
            yAxis:
              format:
                unit: requests/sec
                decimalPlaces: 1
              min: 0
            visual:
              display: line
              lineWidth: 2
              areaOpacity: 0.2
            thresholds:
              mode: absolute
              defaultColor: green
              steps:
                - value: 10
                  color: red
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (service_name) (rate(app_requests_total[5m]))
                  seriesNameFormat: "{{service_name}}"
    by-env:
      kind: Panel
      spec:
        display:
          name: Requests per second by environment
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
                  query: sum by (deployment_environment) (rate(app_requests_total[5m]))
                  seriesNameFormat: "{{deployment_environment}}"
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
    - kind: Grid
      spec:
        display:
          title: Details
          collapse:
            open: false
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/by-env"
```

## Step 4: Check and apply

```sh
percli lint -f dashboard-traffic.yaml
percli apply -f dashboard-traffic.yaml
```

Open `http://perses.localtest.me:8080/projects/inventory/dashboards/traffic`. The first panel has a table legend on the right, and the group `Details` is closed under it.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the panel `rate` and build a new one | The grader checks that the original key is still there and still in the first layout |
| Put `by-env` in the first layout | The second layout is the group `Details`; the grader looks for the panel there |
| Leave out `collapse` | The group starts open, so the first screen is crowded again |
