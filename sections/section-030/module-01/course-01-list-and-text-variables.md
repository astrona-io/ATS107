# List And Text Variables

A team that runs the same service in two environments wants one dashboard with an environment dropdown, not two dashboards. This part builds that dropdown. It shows the two kinds of variables Perses has, the fields that control a list, and how a query uses the value.

## Two kinds of variables

Every variable in a dashboard is an entry in `spec.variables`, with a `kind` and a `spec`:

| Kind | What the reader gets | Where the values come from |
| --- | --- | --- |
| `TextVariable` | A text field | The `value` in the spec, which the reader can change unless `constant: true` |
| `ListVariable` | A dropdown | A variable plugin, such as `StaticListVariable` or a query against a backend |

Both kinds have a `name`, which queries use as `$name`, and an optional `display` with a human name, a description and `hidden`. A hidden variable still works in queries but does not appear at the top of the dashboard.

## A static list

A `StaticListVariable` is a list you write yourself. It fits values that change rarely, such as environment names. Save this as `dashboard-variables-demo.yaml`:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: variables-demo
  project: inventory
spec:
  display:
    name: Variables demo
  duration: 1h
  variables:
    - kind: TextVariable
      spec:
        name: team
        display:
          name: Team
          hidden: false
        value: shop
        constant: true
    - kind: ListVariable
      spec:
        name: env
        display:
          name: Environment
          hidden: false
        allowAllValue: false
        allowMultiple: false
        defaultValue: production
        plugin:
          kind: StaticListVariable
          spec:
            values:
              - production
              - staging
  panels:
    requests:
      kind: Panel
      spec:
        display:
          name: Requests in $env
        plugin:
          kind: TimeSeriesChart
          spec: {}
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (service_name) (rate(app_requests_total{deployment_environment="$env"}[5m]))
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/requests"
```

Apply it:

```sh
percli apply -f dashboard-variables-demo.yaml
```

Then open `http://perses.localtest.me:8080/projects/inventory/dashboards/variables-demo`. The dropdown `Environment` starts at `production`, the `defaultValue`. Switch it to `staging`, and the panel shows only `checkout`, because `payments` only runs in production. The `Team` field shows `shop` and cannot be changed, because the text variable is `constant`.

## What Perses does with `$env`

Before the browser sends the query through the proxy, it writes the selected value into the query text in place of `$env`. With `staging` selected, Prometheus receives `deployment_environment="staging"`. You can send that same text yourself to see what the panel will show:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total{deployment_environment="staging"}[5m]))' \
  | jq -r '.data.result[].metric.service_name'
```

The answer is `checkout` alone. Testing a variable this way, with the value written in by hand, separates a wrong value from a wrong query. The panel title `Requests in $env` shows that variables also work in display names.

## The fields that control a list

A `ListVariable` has more fields than the demo uses. These are the ones you meet most:

| Field | What it does |
| --- | --- |
| `allowMultiple` | Lets the reader pick several values at once |
| `allowAllValue` | Adds an `All` entry that selects every value |
| `customAllValue` | The text written into the query when `All` is selected, instead of every value; for example `.*` |
| `defaultValue` | The value selected when the dashboard opens; a list of values when `allowMultiple` is on |
| `sort` | `none`, `alphabetical-asc`, `alphabetical-desc`, `numerical-asc`, `numerical-desc`, `alphabetical-ci-asc` or `alphabetical-ci-desc` (`ci` ignores upper and lower case) |
| `capturingRegexp` | A regular expression that filters the values; only values that match stay in the list |

Each value of a static list can also be an object with a `value` and a `label`, when the text shown in the dropdown should differ from the text written into the query: `{value: production, label: Production}`.

Turning on `allowMultiple` changes what the query receives. One value is written as it is; several values are written as a group, and `deployment_environment="$env"` with two values selected no longer matches anything. How a group is written, and how to keep the query valid, is a question of interpolation formats.

You now know the two kinds of variables, how a static list is built, and how a query uses the selected value. Most lists, though, should not be typed by hand: their values already exist in the backend.

## Common pitfalls

> [!WARNING]
> - **A `defaultValue` that is not in the list.** The dropdown opens on a value that does not exist, and the panels are empty.
> - **`allowMultiple` with an `=` matcher.** Several values do not fit `label="..."`. Use `=~`.
> - **A static list that goes stale.** When the backend gets a new environment, the list does not. Prefer a list read from the backend for values that change.
> - **A hidden variable you forgot.** `hidden: true` keeps it out of sight, but its value still changes every query that uses it.
