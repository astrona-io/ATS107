# Datasources Inside A Dashboard

Sometimes a datasource belongs to exactly one dashboard. A report dashboard may read from a Prometheus that no other dashboard uses, and creating a project datasource for it would make every dashboard in the project able to see it. Perses lets a dashboard carry its own datasources in the field `spec.datasources`. This part shows the field, the proxy path of such a datasource, and the rule that decides which datasource a panel uses.

## The field spec.datasources

A dashboard is a resource with `spec.panels`, `spec.layouts`, `spec.variables` and also `spec.datasources`. The last field is a map. Each key is a datasource name, and each value has the same two parts as a project datasource: `default` and `plugin`. There is no `metadata` block, because the dashboard itself is the owner.

A panel query selects such a datasource the same way it selects any other: by `kind` and `name`.

```yaml
datasource:
  kind: PrometheusDatasource
  name: reports-prometheus
```

Perses looks for the name in the dashboard first, then in the project, then in the global datasources. A dashboard datasource therefore wins over a project or global datasource of the same name.

## Build a dashboard with its own datasource

Save this as `dashboard-reports.yaml`. The dashboard has one datasource, `reports-prometheus`, and one panel that uses it:

<!-- astrona:playground:renew -->

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

Perses stores the dashboard and the datasource together. Check that the project has no datasource of that name:

```sh
percli get dts
```

The name `reports-prometheus` is not in the list, because the datasource exists only inside the dashboard.

## The proxy path of a dashboard datasource

A dashboard datasource has its own proxy path. It names the project, the dashboard and the datasource:

```sh
curl -s http://perses.localtest.me:8080/proxy/projects/inventory/dashboards/reports/datasources/reports-prometheus/api/v1/query \
  --data-urlencode 'query=up' | jq '.data.result | length'
```

The number is at least one. The same path with another dashboard name in it fails, because the datasource does not exist there. This is the property that makes dashboard datasources safe to use for one-off sources: no other dashboard can reach them.

## Secrets and dashboard datasources

A dashboard datasource that needs credentials takes them from a project `Secret` of the same project, by name in `proxy.spec.secret`, exactly as a project datasource does. A `GlobalSecret` belongs to global datasources.

You now know where all three scopes of a datasource are written and how each one is called. The next part gives you an order to follow when one of them fails.

## Common pitfalls

> [!WARNING]
> - **Looking for a dashboard datasource in `percli get dts`.** That list shows project datasources only. Read it with `percli describe dashboard reports -o json | jq '.spec.datasources'`.
> - **A panel that names a datasource that does not exist at any scope.** Perses accepts the dashboard, but the panel stays empty. Test the proxy path to find out.
> - **Copying a dashboard without its datasources.** If you rebuild the dashboard from panels alone, the `datasources` map is lost.

## Your mission: Give A Dashboard Its Own Datasource

You can now store a datasource inside a dashboard and prove it answers through the dashboard proxy path. The mission starts with a dashboard `reports` whose panel names a datasource that exists nowhere, so the panel is empty. You add the missing dashboard datasource without creating a project or global one.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-010-02
astrona start ats-107-playground-010-02
```
