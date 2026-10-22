# Overview: Show Metrics, Logs, Traces And Profiles (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the backends and Perses, creates the starting resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, and `percli` 0.54.0 on your PATH.
- The namespace **`observability`** with Prometheus, Loki, Tempo and Pyroscope, and telemetry for `checkout` and `payments` in `production` and `staging`.
- The project **`inventory`** and a default global datasource for each backend: `prometheus`, `loki`, `tempo` and `pyroscope`.

Start the port-forward in a second terminal and leave it running, then log in:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Helpers

Paste these once in each new terminal. Each one sends a query through the matching global datasource and prints how much came back: series for PromQL, streams for LogQL, traces for TraceQL.

```sh
PERSES_URL="http://perses.localtest.me:8080"
count_series() {
  curl -s "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/query" \
    --data-urlencode "query=$1" | jq '.data.result | length'
}
count_streams() {
  curl -s -G "$PERSES_URL/proxy/globaldatasources/loki/loki/api/v1/query_range" \
    --data-urlencode "query=$1" | jq '.data.result | length'
}
count_traces() {
  curl -s -G "$PERSES_URL/proxy/globaldatasources/tempo/api/search" \
    --data-urlencode "q=$1" | jq '.traces | length'
}
```

Use them like this: `count_series 'app_requests_total'`, `count_streams '{service_name="payments"}'`, `count_traces '{resource.service.name="payments"}'`.

## Practice tasks

- Find a label name that differs between PromQL and TraceQL, and prove it with `count_series` and `count_traces`.
- Add a `ScatterChart` panel with a `TempoTraceQuery` to a dashboard and compare it with a `TraceTable` on the same query.
- Copy one trace ID from the Tempo search answer into a `TracingGanttChart` panel.
- Remove one panel's layout item and confirm the panel disappears while `percli describe dashboard` still shows it.
- Change a `FlameChart` spec to leave out `palette` and read the error `percli apply` prints.
