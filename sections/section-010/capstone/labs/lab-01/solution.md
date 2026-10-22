# Solution: Repair The Datasources Of A Project

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: Prometheus answers through the global datasource, Loki answers through the project datasource with its Secret, and Tempo answers through the project datasource while its endpoint list still refuses `/api/status/buildinfo`.

Start the port-forward in a second terminal, log in and select the project before the first step:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Step 1: Test each datasource through its proxy path

Send one small request per datasource and print only the status code. The three requests use the paths the dashboards use:

```sh
curl -s -o /dev/null -w 'prometheus %{http_code}\n' \
  http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query --data-urlencode 'query=up'
curl -s -o /dev/null -w 'loki %{http_code}\n' \
  http://perses.localtest.me:8080/proxy/projects/inventory/datasources/loki/loki/api/v1/labels
curl -s -o /dev/null -w 'tempo %{http_code}\n' -G \
  http://perses.localtest.me:8080/proxy/projects/inventory/datasources/tempo/api/search \
  --data-urlencode 'q={resource.service.name="checkout"}'
```

None of the three is `200`, and each fails for a different reason. Read each datasource next.

## Step 2: Prometheus points at the wrong port

```sh
percli describe gdts prometheus
```

The proxy `url` is `http://prometheus.observability:9091`. Prometheus listens on `9090`, so the Perses server cannot connect. Save the corrected datasource as `globaldatasource-prometheus.yaml`; the endpoint list stays as it was:

```yaml
kind: GlobalDatasource
metadata:
  name: prometheus
spec:
  default: true
  plugin:
    kind: PrometheusDatasource
    spec:
      proxy:
        kind: HTTPProxy
        spec:
          url: http://prometheus.observability:9090
          allowedEndpoints:
            - endpointPattern: /api/v1/labels
              method: POST
            - endpointPattern: /api/v1/series
              method: POST
            - endpointPattern: /api/v1/metadata
              method: GET
            - endpointPattern: /api/v1/query
              method: POST
            - endpointPattern: /api/v1/query_range
              method: POST
            - endpointPattern: /api/v1/label/([a-zA-Z0-9_-]+)/values
              method: GET
```

Apply it:

```sh
percli apply -f globaldatasource-prometheus.yaml
```

## Step 3: Loki's Secret holds a stale password

```sh
percli describe dts loki
```

The datasource looks right: the gateway URL, the Secret `loki-gateway-auth`, a read-only endpoint list. The status code was `401`, which comes from the gateway, so the credentials are wrong. The Secret holds an old password. Save the corrected Secret as `secret-loki-gateway-auth.yaml`:

```yaml
kind: Secret
metadata:
  name: loki-gateway-auth
  project: inventory
spec:
  basicAuth:
    username: perses
    password: loki-gateway-password
```

Apply it:

```sh
percli apply -f secret-loki-gateway-auth.yaml
```

The datasource itself does not change: it references the Secret by name, so the new password takes effect at once.

## Step 4: Tempo's endpoint list blocks search

```sh
percli describe dts tempo
```

Its `allowedEndpoints` holds only `GET /api/echo`. The Perses server refuses every search before it reaches Tempo. Replace the list with the paths trace search, tag lookups and trace lookup need. Save this as `datasource-tempo.yaml`:

```yaml
kind: Datasource
metadata:
  name: tempo
  project: inventory
spec:
  default: true
  plugin:
    kind: TempoDatasource
    spec:
      proxy:
        kind: HTTPProxy
        spec:
          url: http://tempo.observability:3200
          allowedEndpoints:
            - endpointPattern: /api/search
              method: GET
            - endpointPattern: /api/search/tags
              method: GET
            - endpointPattern: /api/search/tag/([a-zA-Z0-9_.-]+)/values
              method: GET
            - endpointPattern: /api/v2/search/tags
              method: GET
            - endpointPattern: /api/v2/search/tag/([a-zA-Z0-9_.-]+)/values
              method: GET
            - endpointPattern: /api/traces/([a-zA-Z0-9]+)
              method: GET
            - endpointPattern: /api/v2/traces/([a-zA-Z0-9]+)
              method: GET
```

Apply it:

```sh
percli apply -f datasource-tempo.yaml
```

## Step 5: Prove all three

Count the series, streams and traces each datasource returns:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=up' | jq '.data.result | length'
curl -s -G http://perses.localtest.me:8080/proxy/projects/inventory/datasources/loki/loki/api/v1/query_range \
  --data-urlencode 'query={service_name="checkout"}' | jq '.data.result | length'
curl -s -G http://perses.localtest.me:8080/proxy/projects/inventory/datasources/tempo/api/search \
  --data-urlencode 'q={resource.service.name="checkout"}' | jq '.traces | length'
```

All three numbers are now greater than zero. Check that Tempo still refuses an unlisted path:

```sh
curl -s -o /dev/null -w '%{http_code}\n' \
  http://perses.localtest.me:8080/proxy/projects/inventory/datasources/tempo/api/status/buildinfo
```

The status is not `200`.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the project `tempo` and `loki` datasources | Dashboards fall back to the global ones; global `loki` has no credentials, and the grader requires the project datasources |
| Remove Tempo's `allowedEndpoints` | Search works, but every Tempo path is open; the grader requests `/api/status/buildinfo` |
| Put the password in a proxy header | It works, but the grader requires the Secret |
| Change the gateway password to the stale one | The gateway is shared; fix the Secret instead |
