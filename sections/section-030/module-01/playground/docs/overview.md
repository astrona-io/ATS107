# Overview: Make Dashboards Interactive With Variables (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the backends and Perses, creates the starting resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, and `percli` 0.54.0 on your PATH.
- The namespace **`observability`** with Prometheus, Loki, Tempo and Pyroscope, and telemetry for `checkout` and `payments` in `production` and `staging`.
- The project **`inventory`**, a default global datasource for each backend, and a second, non-default Prometheus datasource, **`prometheus-replica`**, that reaches the same Prometheus.

Start the port-forward in a second terminal and leave it running, then log in:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Helpers

Paste these once in each new terminal. `label_values` lists the values a Prometheus label has on the series that match a selector, as a `PrometheusLabelValuesVariable` sees them. `count_series` counts the series a PromQL query returns, so you can test a query with the variable values written in by hand.

```sh
PERSES_URL="http://perses.localtest.me:8080"
label_values() {
  curl -s -G "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/label/$1/values" \
    --data-urlencode "match[]=$2" | jq -r '.data[]'
}
count_series() {
  curl -s "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/query" \
    --data-urlencode "query=$1" | jq '.data.result | length'
}
```

Use them like this: `label_values service_name 'app_requests_total{deployment_environment="staging"}'`, `count_series 'app_requests_total{service_name=~"(checkout|payments)"}'`.

## Practice tasks

- Turn on `allowMultiple` for a service variable and watch which queries break; fix them with `=~`.
- Write the same service list as a `PrometheusPromQLVariable` that only lists services with traffic.
- Add a `LokiLabelValuesVariable` for `deployment_environment` and compare its values with the Prometheus one.
- Create a `GlobalVariable` and a project `Variable` with the same name and different values, and see which one a dashboard shows.
- Try `${service:csv}`, `${service:pipe}` and `${service:json}` in a panel title to see each format.
