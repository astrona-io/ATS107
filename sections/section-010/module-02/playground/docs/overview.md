# Overview: Tune And Scope Datasources (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the backends and Perses, creates the starting resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, and `percli` 0.54.0 on your PATH.
- The namespace **`observability`** with Prometheus (port 9090), Loki (3100) with a gateway, Tempo (3200) and Pyroscope (4040), and telemetry for `checkout` and `payments`.
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

Paste these once in each new terminal. `proxy_status` prints the HTTP status code of a GET request through the Perses proxy. `proxy_get` prints the JSON an endpoint returns.

```sh
proxy_status() {
  curl -s -o /dev/null -w '%{http_code}\n' "http://perses.localtest.me:8080/proxy/$1"
}
proxy_get() {
  curl -s "http://perses.localtest.me:8080/proxy/$1" | jq .
}
```

Use them like this: `proxy_status globaldatasources/loki/loki/api/v1/labels`, `proxy_get globaldatasources/prometheus/api/v1/label/service_name/values`.

## Practice tasks

- Create a project `Datasource` with `scrapeInterval: 30 seconds` and read the error `percli apply` prints. Then fix the value to `30s`.
- Add `queryParams` to a datasource and compare a query through it with the same query through the global datasource.
- Create a project datasource for each of Loki, Tempo and Pyroscope and send one request through each.
- Put a datasource named `prometheus` into a dashboard and predict which datasource its panel uses. Check with the dashboard proxy path.
- Point a datasource at a wrong port and compare its status code with a datasource that works.
