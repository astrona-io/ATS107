# Solution: Add A Datasource Selector And A Service Variable

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the two variables exist in the right order with the right plugins, the panel query uses the datasource variable and a multi-value matcher, and the query returns data for two services through both Prometheus datasources.

## Step 1: Connect percli and look at the dashboard

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

```sh
percli describe dashboard services
```

The dashboard has no variables, and the query of `requests` holds `service_name="checkout"`.

## Step 2: Check the values the variable will list

Ask both datasources for the values of `service_name` on `app_requests_total`:

```sh
for datasource in prometheus prometheus-replica; do
  curl -s -G "http://perses.localtest.me:8080/proxy/globaldatasources/$datasource/api/v1/label/service_name/values" \
    --data-urlencode 'match[]=app_requests_total' | jq -c '.data'
done
```

Both answer `["checkout","payments"]`.

## Step 3: Write and apply the dashboard

The `prometheus` variable comes first, because `service` reads its values from the datasource `prometheus` selects. The query uses `=~`, because with two services selected `$service` becomes `(checkout|payments)`. Save this as `dashboard-services.yaml`:

```yaml
kind: Dashboard
metadata:
  name: services
  project: inventory
spec:
  display:
    name: Services
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: prometheus
        display:
          name: Prometheus
          hidden: false
        allowAllValue: false
        allowMultiple: false
        plugin:
          kind: DatasourceVariable
          spec:
            datasourcePluginKind: PrometheusDatasource
    - kind: ListVariable
      spec:
        name: service
        display:
          name: Service
          hidden: false
        allowAllValue: true
        allowMultiple: true
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            datasource: $prometheus
            labelName: service_name
            matchers:
              - app_requests_total
  panels:
    requests:
      kind: Panel
      spec:
        display:
          name: Request rate by service
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  datasource: $prometheus
                  query: sum by (service_name) (rate(app_requests_total{service_name=~"$service"}[5m]))
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
percli apply -f dashboard-services.yaml
```

## Step 4: Test the query with two services

Write the two-service value in by hand, the way Perses does, and send the query:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total{service_name=~"(checkout|payments)"}[5m]))' \
  | jq -r '.data.result[].metric.service_name'
```

Both services come back. Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/services`, switch the datasource, and select both services.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep `service_name="$service"` | One service works; two become `(checkout\|payments)`, which `=` never matches |
| Leave the query's datasource fixed | The datasource dropdown changes nothing; the grader checks `datasource: $prometheus` |
| Put `service` before `prometheus` | `service` cannot load its values before the datasource is known |
| A static list of the two services | It goes stale when a service is added; the grader requires label values |
