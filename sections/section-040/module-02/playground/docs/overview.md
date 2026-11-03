# Overview: Filter Logs And Traces With Several Selections (Playground)

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

Paste these once in each new terminal. `services_in` lists the services of the environments you pass, written as a regular expression the way a variable with several values writes them. `count_logs` and `count_traces` send a log or trace query and print how many streams or traces come back.

```sh
PERSES_URL="http://perses.localtest.me:8080"
services_in() {
  curl -s -G "$PERSES_URL/proxy/globaldatasources/prometheus/api/v1/label/service_name/values" \
    --data-urlencode "match[]=app_requests_total{deployment_environment=~\"$1\"}" | jq -c '.data'
}
count_logs() {
  curl -s -G "$PERSES_URL/proxy/globaldatasources/loki/loki/api/v1/query_range" \
    --data-urlencode "query=$1" | jq '.data.result | length'
}
count_traces() {
  curl -s -G "$PERSES_URL/proxy/globaldatasources/tempo/api/search" \
    --data-urlencode "q=$1" | jq '.traces | length'
}
```

Use them like this: `services_in 'staging'`, `services_in '(production|staging)'`, `count_logs '{service_name=~"(checkout|payments)"} |= "order"'`, `count_traces '{resource.service.name =~ ".*" && duration > 10ms}'`.

## Practice tasks

- Run `services_in 'staging'` and `services_in '(production|staging)'` and explain why the second list is longer.
- Run `count_logs` with `service_name="(checkout|payments)"` and again with `=~`. Explain the difference.
- Change the text in `|= "order"` to a word that is not in the log lines and watch the count drop to zero.
- Run `count_traces` with `duration > 10ms`, `100ms` and `1s` and find the threshold where the count reaches zero.
- Build a dashboard with an `env` and a `service` variable, move `service` above `env` and watch the service list.
- Add a `TextVariable` for the search text and use it in a log query with `|= "$search"`.
