# Solution: Build A Unified Incident Dashboard

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks four things: the variable order and the `$env` in the service matcher, the service list for each environment, that each of the three queries uses both variables, and that every panel returns data for two real pairs.

## Step 1: Connect percli

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Step 2: Test the cascade before you build it

Ask Prometheus for the services of `staging`, with the environment written into the matcher:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/label/service_name/values \
  --data-urlencode 'match[]=app_requests_total{deployment_environment="staging"}' | jq -c '.data'
```

The answer is `["checkout"]`. This is the exact call the `service` variable will make.

## Step 3: Write and apply the dashboard

`env` comes first, because the matcher of `service` uses `$env`. Each query names the labels the way its backend does. Save this as `dashboard-incident.yaml`:

```yaml
kind: Dashboard
metadata:
  name: incident
  project: inventory
spec:
  display:
    name: Incident
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: env
        display:
          name: Environment
          hidden: false
        allowAllValue: false
        allowMultiple: false
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: deployment_environment
            matchers:
              - app_requests_total
    - kind: ListVariable
      spec:
        name: service
        display:
          name: Service
          hidden: false
        allowAllValue: false
        allowMultiple: false
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: service_name
            matchers:
              - app_requests_total{deployment_environment="$env"}
  panels:
    request-rate:
      kind: Panel
      spec:
        display:
          name: Request rate
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (service_name) (rate(app_requests_total{deployment_environment="$env", service_name="$service"}[5m]))
    logs:
      kind: Panel
      spec:
        display:
          name: Logs
        plugin:
          kind: LogsTable
          spec:
            showTime: true
        queries:
          - kind: LogQuery
            spec:
              plugin:
                kind: LokiLogQuery
                spec:
                  query: '{deployment_environment="$env", service_name="$service"}'
    traces:
      kind: Panel
      spec:
        display:
          name: Traces
        plugin:
          kind: TraceTable
          spec: {}
        queries:
          - kind: TraceQuery
            spec:
              plugin:
                kind: TempoTraceQuery
                spec:
                  query: '{resource.deployment.environment="$env" && resource.service.name="$service"}'
                  limit: 20
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/request-rate"
          - x: 0
            y: 8
            width: 12
            height: 10
            content:
              $ref: "#/spec/panels/logs"
          - x: 12
            y: 8
            width: 12
            height: 10
            content:
              $ref: "#/spec/panels/traces"
```

Apply it:

```sh
percli apply -f dashboard-incident.yaml
```

## Step 4: Prove every panel for a real pair

Send the three queries with `production` and `payments` written in:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total{deployment_environment="production", service_name="payments"}[5m]))' \
  | jq '.data.result | length'
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/loki/loki/api/v1/query_range \
  --data-urlencode 'query={deployment_environment="production", service_name="payments"}' | jq '.data.result | length'
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/tempo/api/search \
  --data-urlencode 'q={resource.deployment.environment="production" && resource.service.name="payments"}' \
  | jq '.traces | length'
```

All three numbers are greater than zero. Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/incident`, switch between `production` and `staging`, and watch the service list change.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| A service matcher without `$env` | `staging` lists `payments`, a pair with no data; the grader checks the `staging` list |
| `service_name` in TraceQL | Tempo has no such attribute; the traces panel stays empty |
| A static list of services | It does not follow the environment and goes stale |
| `service` before `env` | `$env` has no value when the service list loads |
