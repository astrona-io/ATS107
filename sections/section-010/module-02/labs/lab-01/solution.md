# Solution: Give A Dashboard Its Own Datasource

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the dashboard defines the datasource with the right kind, address and `scrapeInterval`; no project or global datasource has the same name; and a query through the dashboard proxy path returns data.

## Step 1: Connect percli

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Step 2: See why the panel is empty

Read the panel query and the datasources of the dashboard:

```sh
percli describe dashboard reports -o json | jq '.spec.datasources, .spec.panels.requests.spec.queries[0].spec.plugin.spec.datasource'
```

The first value is `null`, and the query asks for the datasource `reports-prometheus`. Check that no project datasource has the name:

```sh
percli get dts
```

## Step 3: Add the datasource to the dashboard

Save this as `dashboard-reports.yaml`. It is the same dashboard with a `datasources` block:

```yaml
kind: Dashboard
metadata:
  name: reports
  project: inventory
spec:
  display:
    name: Reports
  duration: 1h
  datasources:
    reports-prometheus:
      default: false
      plugin:
        kind: PrometheusDatasource
        spec:
          scrapeInterval: 30s
          proxy:
            kind: HTTPProxy
            spec:
              url: http://prometheus.observability:9090
  panels:
    requests:
      kind: Panel
      spec:
        display:
          name: Requests per second
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource:
                    kind: PrometheusDatasource
                    name: reports-prometheus
                  query: sum by (service_name) (rate(app_requests_total[5m]))
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
percli apply -f dashboard-reports.yaml
```

## Step 4: Test the dashboard proxy path

```sh
curl -s http://perses.localtest.me:8080/proxy/projects/inventory/dashboards/reports/datasources/reports-prometheus/api/v1/query \
  --data-urlencode 'query=up' | jq '.data.result | length'
```

The number is at least one.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a project `Datasource` named `reports-prometheus` | The panel works, but every dashboard in the project can now use it, and the grader checks that none can |
| Rename the datasource in the panel to `prometheus` | The panel works, but the query no longer uses the datasource the task asks for |
| Use the proxy path of a project datasource to test | That path does not exist for a dashboard datasource |
