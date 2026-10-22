# Solution: Repair A Dashboard That Shows Nothing

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the four original panels still exist, every panel is in the layout, and every panel's query returns data through the Perses proxy.

## Step 1: Connect percli and read the dashboard

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

Save the dashboard to a file, so you can edit it and apply it back:

```sh
percli describe dashboard signals > dashboard-signals.yaml
```

## Step 2: The request rate uses a label that does not exist

The `requests` query is `sum by (service) (rate(app_requests_total{service="checkout"}[5m]))`. Test it through the proxy:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=app_requests_total{service="checkout"}' | jq '.data.result | length'
```

The answer is `0`: Prometheus has no label `service`. The label is `service_name`. In `dashboard-signals.yaml`, change the query to:

```yaml
query: sum by (service_name) (rate(app_requests_total{service_name="checkout"}[5m]))
```

## Step 3: The logs panel names a datasource that does not exist

The `logs` query has a `datasource` with `kind: LokiDatasource` and `name: loki-archive`. Check whether that datasource exists, globally or in the project:

```sh
percli get gdts
percli get dts
```

Neither list has `loki-archive`; it existed at the other team. Remove the whole `datasource` block from the `logs` query, so it uses the default `LokiDatasource`, the global `loki`. The query `{service_name="checkout"}` itself is correct.

## Step 4: The traces panel is not in the layout

List the panel keys the layout points at:

```sh
percli describe dashboard signals -o json | jq -r '.spec.layouts[].spec.items[].content["$ref"]'
```

The list has `requests`, `logs` and `profile`, but no `traces`. Add an item under `layouts[0].spec.items` in `dashboard-signals.yaml`:

```yaml
- x: 0
  y: 16
  width: 24
  height: 8
  content:
    $ref: "#/spec/panels/traces"
```

## Step 5: Apply and check

Apply the edited dashboard:

```sh
percli apply -f dashboard-signals.yaml
```

The file you saved with `percli describe` also holds fields Perses manages, such as the creation time and the version. If `percli apply` complains about one of them, delete it from `metadata` and apply again. Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/signals` and confirm all four panels show data.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a datasource named `loki-archive` | The panel works, but you added a datasource to fit a stale name; the task forbids new datasources |
| Delete the `traces` panel | The grader checks all four original panels still exist |
| Write a new dashboard with another name | The team opens `signals`; the grader reads `signals` |
