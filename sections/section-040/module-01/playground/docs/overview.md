# Overview: Build A Unified Incident Dashboard (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the backends and Perses, creates the starting resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, and `percli` 0.54.0 on your PATH.
- The namespace **`observability`** with Prometheus, Loki, Tempo and Pyroscope. Telemetry arrives for `checkout` in `production` and `staging`, and for `payments` in `production` only.
- The project **`inventory`** and a default global datasource for each backend.

Start the port-forward in a second terminal and leave it running, then log in:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Helpers

Paste these once in each new terminal. `services_in` lists the services of one environment, the way a cascading service variable does. `check_pair` sends the metrics, logs and traces query for one environment and service and prints how much each returns.

```sh
PERSES_URL="http://perses.localtest.me:8080"
services_in() {
  curl -s -G "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/label/service_name/values" \
    --data-urlencode "match[]=app_requests_total{deployment_environment=\"$1\"}" | jq -c '.data'
}
check_pair() {
  echo "metrics: $(curl -s "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/query" \
    --data-urlencode "query=app_requests_total{deployment_environment=\"$1\", service_name=\"$2\"}" | jq '.data.result | length')"
  echo "logs: $(curl -s -G "$PERSES_URL/proxy/globaldatasources/loki/loki/api/v1/query_range" \
    --data-urlencode "query={deployment_environment=\"$1\", service_name=\"$2\"}" | jq '.data.result | length')"
  echo "traces: $(curl -s -G "$PERSES_URL/proxy/globaldatasources/tempo/api/search" \
    --data-urlencode "q={resource.deployment.environment=\"$1\" && resource.service.name=\"$2\"}" | jq '.traces | length')"
}
```

Use them like this: `services_in staging`, `check_pair production payments`.

## Practice tasks

- Run `check_pair staging payments` and explain the three zeros.
- Move the `service` variable above `env` in a dashboard and watch the service list.
- Turn on `allowMultiple` for `env` and change every query and matcher so two environments still work.
- Add a third variable, a list of trace root names, and use it in the trace query only.
- Replace the Prometheus-based `service` variable with a `LokiLabelValuesVariable` and compare the lists.
