# Overview: Show Single Numbers, Gauges And Bars (Playground)

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

Paste these once in each new terminal. `count_series` sends an instant PromQL query through the default `prometheus` datasource and prints how many series came back. `value_of` prints the first sample value, which is the number a stat chart with `calculation: last` would show.

```sh
PERSES_URL="http://perses.localtest.me:8080"
count_series() {
  curl -s "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/query" \
    --data-urlencode "query=$1" | jq '.data.result | length'
}
value_of() {
  curl -s "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/query" \
    --data-urlencode "query=$1" | jq -r '.data.result[0].value[1]'
}
```

Use them like this: `count_series 'sum by (service_name) (rate(app_requests_total[5m]))'`, `value_of 'sum(rate(app_requests_total[5m]))'`.

## Practice tasks

- Build a `StatChart` and switch `calculation` between `last`, `mean` and `max`. Compare each number with `value_of`.
- Show a ratio query with `unit: percent` and then with `unit: percent-decimal`, and explain which one is right.
- Add `thresholds` to a `GaugeChart` with `mode: absolute` and then `mode: percent`, and watch where the colours change.
- Turn a `BarChart` into a `PieChart` on the same query and compare `sort` and `mode`.
- Add a `Markdown` panel that explains the thresholds of the gauge next to it.
