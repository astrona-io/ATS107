# Loki, Tempo And Pyroscope Datasources

Metrics are one signal. Logs, traces and profiles come from three other backends, and each one has its own datasource kind and its own paths. A dashboard author who cannot name the kind and the path of each backend cannot test a datasource, and cannot tell whether an `allowedEndpoints` list is complete. This part creates a datasource for each backend and sends one request through each.

## Four kinds, one shape

The four HTTP datasource plugins share the same `proxy` block. Only the plugin kind and a few optional fields differ:

| Backend | Datasource kind | Extra fields |
| --- | --- | --- |
| Prometheus | `PrometheusDatasource` | `scrapeInterval`, `queryParams`, `exemplars` |
| Loki | `LokiDatasource` | none beyond `proxy` or `directUrl` |
| Tempo | `TempoDatasource` | none beyond `proxy` or `directUrl` |
| Pyroscope | `PyroscopeDatasource` | `minStep` |

`minStep` on a Pyroscope datasource is the smallest time step for profile time series, written as a duration such as `15s`.

## Loki: a datasource that skips the gateway

In the playground, the global `loki` datasource points at a gateway that needs a password. Loki itself has no authentication, and it listens on port `3100` in the namespace `observability`. Save this as `datasource-loki-direct.yaml`; it is a project datasource that talks to Loki without the gateway:

<!-- astrona:playground:renew -->

```yaml
kind: Datasource
metadata:
  name: loki-direct
  project: inventory
spec:
  default: false
  plugin:
    kind: LokiDatasource
    spec:
      proxy:
        kind: HTTPProxy
        spec:
          url: http://loki.observability:3100
```

Apply it:

```sh
percli apply -f datasource-loki-direct.yaml
```

Loki's own HTTP API starts with `/loki/api/v1`, so the proxy path repeats the word `loki` after the datasource name. Ask for the list of label names:

```sh
curl -s http://perses.localtest.me:8080/proxy/projects/inventory/datasources/loki-direct/loki/api/v1/labels | jq '.data'
```

The list contains `service_name`. The request reached Loki through the Perses server, with no credentials, because this datasource does not use the gateway.

## Tempo and Pyroscope

Tempo answers search requests on `/api/search`, and the query goes in the parameter `q`. Pyroscope answers on service paths that start with `querier.v1.QuerierService`. Save the next file as `datasource-tempo-inventory.yaml`:

```yaml
kind: Datasource
metadata:
  name: tempo-inventory
  project: inventory
spec:
  default: false
  plugin:
    kind: TempoDatasource
    spec:
      proxy:
        kind: HTTPProxy
        spec:
          url: http://tempo.observability:3200
```

And this one as `datasource-pyroscope-inventory.yaml`:

```yaml
kind: Datasource
metadata:
  name: pyroscope-inventory
  project: inventory
spec:
  default: false
  plugin:
    kind: PyroscopeDatasource
    spec:
      minStep: 15s
      proxy:
        kind: HTTPProxy
        spec:
          url: http://pyroscope.observability:4040
```

Apply both:

```sh
percli apply -f datasource-tempo-inventory.yaml
percli apply -f datasource-pyroscope-inventory.yaml
```

Send one request through each. Tempo first, with a TraceQL query for the service `checkout`:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/projects/inventory/datasources/tempo-inventory/api/search \
  --data-urlencode 'q={resource.service.name="checkout"}' | jq '.traces | length'
```

Then Pyroscope, which takes a POST with a JSON body:

```sh
curl -s -X POST -H 'Content-Type: application/json' -d '{}' \
  http://perses.localtest.me:8080/proxy/projects/inventory/datasources/pyroscope-inventory/querier.v1.QuerierService/ProfileTypes \
  | jq '.profileTypes | length'
```

Both numbers are greater than zero when the backends hold data. Tempo and Pyroscope need a minute after the playground starts before they show data, so run the commands again if you see `0`.

## Why the path matters for allowedEndpoints

The path in each request is the same text an `allowedEndpoints` entry must match. If you restrict the Tempo datasource to `GET /api/search`, trace search works and a request for a single trace by its ID, which uses a different path, is refused. Before you restrict a datasource, list the paths its plugin uses, and keep the list as short as those paths allow.

You can now create a datasource for each backend and prove it answers. A datasource does not have to be a separate resource, though: a dashboard can carry its own, and that is the next topic.

## Common pitfalls

> [!WARNING]
> - **Leaving out the second `loki` in the path.** The proxy path is the datasource name followed by the backend's own path, which here starts with `loki`.
> - **Using the wrong port.** Loki listens on `3100`, Tempo on `3200` and Pyroscope on `4040`. A wrong port makes the Perses server fail to reach the backend.
> - **Testing right after the playground starts.** The backends need a minute to receive data; an empty answer can be a timing problem and not a datasource problem.
