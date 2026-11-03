# Settings Of A Prometheus Datasource

Two datasources can point at the same Prometheus and still behave differently, because a datasource carries settings that change how Perses sends its queries. If you cannot read those settings, you cannot explain why one dashboard works and another does not. This part reads every field of a `PrometheusDatasource` and then creates one with non-default values.

## The two blocks of a datasource

A datasource resource has a `spec` with two levels. The first level, `spec.default`, says whether the datasource is the default of its kind. The second level, `spec.plugin`, names the plugin with `kind` and holds the plugin's own settings in `spec.plugin.spec`.

Print the plugin block of the global `prometheus` datasource:

<!-- astrona:playground:renew -->

```sh
percli describe gdts prometheus -o json | jq '.spec.plugin'
```

The answer has `kind: PrometheusDatasource` and a `spec` with a `proxy` block. The `proxy` block holds `kind: HTTPProxy` and a `spec` with the field `url`, and also the field `allowedEndpoints` you met before.

## proxy or directUrl

Every HTTP datasource plugin, which means Prometheus, Loki, Tempo and Pyroscope, accepts exactly one of two fields. With `proxy`, the browser sends each query to the Perses server and the Perses server forwards it. With `directUrl`, the browser calls the backend address itself, so the address must work from the reader's machine and the backend must accept calls from the page.

Only `proxy` can use a Secret, restrict paths with `allowedEndpoints` and reach an address that exists only inside the cluster. For that reason a datasource that has to be shared by many readers should use `proxy`. A datasource with both fields is not valid, and `percli apply` refuses it.

## The Prometheus fields

Next to the proxy, a `PrometheusDatasource` has three optional fields:

| Field | What it does |
| --- | --- |
| `scrapeInterval` | How often Prometheus scrapes its targets, for example `15s`. Perses uses it as the smallest step of a range query, so a chart never asks for points closer together than the data. |
| `queryParams` | A map of extra query-string parameters that Perses adds to every request, for example `timeout: 30s`. |
| `exemplars.enable` | Turns on exemplars, which are sample trace IDs attached to a metric value. |

A duration such as `scrapeInterval` must be written as numbers with units, for example `30s`, `1m` or `1m30s`. A value such as `30 seconds` does not match the pattern, and `percli apply` rejects the resource before it is stored.

The proxy block also accepts a `headers` map. Perses adds each entry as an HTTP header to every forwarded request. Use it for values that are not secret, such as a tenant identifier. Passwords and tokens belong in a Secret.

## Create a datasource with these settings

Save this as `datasource-prometheus-slow.yaml`. It is a second Prometheus datasource for the project `inventory`, for dashboards that query a slow backend:

```yaml
kind: Datasource
metadata:
  name: prometheus-slow
  project: inventory
spec:
  default: false
  plugin:
    kind: PrometheusDatasource
    spec:
      scrapeInterval: 30s
      queryParams:
        timeout: 60s
      proxy:
        kind: HTTPProxy
        spec:
          url: http://prometheus.observability:9090
          headers:
            X-Team: inventory
```

Apply it:

```sh
percli apply -f datasource-prometheus-slow.yaml
```

Then read the settings back:

```sh
percli describe dts prometheus-slow -o json | jq '.spec.plugin.spec | {scrapeInterval, queryParams, headers: .proxy.spec.headers}'
```

The answer shows the three values you wrote. Now send a query through the new datasource to prove that it still reaches Prometheus:

```sh
curl -s http://perses.localtest.me:8080/proxy/projects/inventory/datasources/prometheus-slow/api/v1/query \
  --data-urlencode 'query=up' | jq '.data.result | length'
```

The number is at least one. The proxy added the `timeout` parameter and the header on the way, and Prometheus accepted both.

You now know the fields of one plugin and the choice between `proxy` and `directUrl`. The other three backends use the same proxy block but answer on different paths, and that is the next topic.

## Common pitfalls

> [!WARNING]
> - **Writing both `proxy` and `directUrl`.** A datasource has exactly one of them.
> - **A `scrapeInterval` that does not match the real scrape interval.** Charts then show gaps or too many points. Read the value from the Prometheus configuration.
> - **Putting a token in `headers`.** The header is stored in plain text next to every other setting. Use a Secret.
