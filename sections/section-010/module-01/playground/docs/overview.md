# Overview: Connect Perses To Your Data Backends (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the backends and Perses, creates the starting resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, and `percli` 0.54.0 on your PATH.
- The namespace **`observability`** with Prometheus, Loki, the `loki-gateway` (basic authentication: lab-only user `perses`, password `loki-gateway-password`), Tempo, Pyroscope, and telemetry for `checkout` and `payments` in `production` and `staging`.
- The project **`inventory`** and the global datasources `prometheus`, `loki`, `tempo` and `pyroscope`. The global `loki` datasource points at the gateway without credentials, so it answers `401`.

Start the port-forward in a second terminal and leave it running, then log in:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Helpers

Paste these once in each new terminal. `proxy_status` prints the HTTP status code of a GET request through the Perses proxy. `prom_count` prints how many series a PromQL query returns through the global `prometheus` datasource.

```sh
proxy_status() {
  curl -s -o /dev/null -w '%{http_code}\n' "http://perses.localtest.me:8080/proxy/$1"
}
prom_count() {
  curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
    --data-urlencode "query=$1" | jq '.data.result | length'
}
```

Use them like this: `proxy_status globaldatasources/loki/loki/api/v1/labels`, `prom_count up`.

## Practice tasks

- Run `percli describe gdts loki` and find why the gateway answers `401`.
- Create a project `Datasource` named `prometheus` that points at the same URL, and predict which one a dashboard in `inventory` now uses. Delete it again with `percli delete dts prometheus`.
- Add `allowedEndpoints` to a project datasource of your own, then compare `proxy_status` for a listed and an unlisted path.
- Create a `Secret` with a wrong password, connect a datasource to it, and compare the status code with the one from a datasource that has no Secret at all.
- Find the Prometheus paths the global datasource allows, and send a query with `prom_count 'sum by (service_name) (rate(app_requests_total[5m]))'`.
