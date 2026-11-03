# Cascades With Many Values

A cascade is a chain of variables where each list depends on the choice before it. With single values the chain is simple: one environment, then the services that run in it. With many values at each step, two things change: the matcher must accept several values, and the reader needs a way to say "all of them".

## A service list for many environments

The first variable lets the reader pick one or several environments. The second lists the services that run in any of them. Save this as `dashboard-explorer.yaml`:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: explorer
  project: inventory
spec:
  display:
    name: Explorer
  duration: 1h
  variables:
    - kind: ListVariable
      spec:
        name: env
        display:
          name: Environment
          hidden: false
        allowAllValue: true
        customAllValue: ".*"
        allowMultiple: true
        defaultValue: "$__all"
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: deployment_environment
            matchers:
              - app_requests_total
    - kind: ListVariable
      spec:
        name: service
        display:
          name: Service
          hidden: false
        allowAllValue: true
        customAllValue: ".*"
        allowMultiple: true
        defaultValue: "$__all"
        sort: alphabetical-asc
        plugin:
          kind: PrometheusLabelValuesVariable
          spec:
            labelName: service_name
            matchers:
              - app_requests_total{deployment_environment=~"$env"}
  panels:
    logs:
      kind: Panel
      spec:
        display:
          name: Logs
        plugin:
          kind: LogsTable
          spec:
            showTime: true
        queries:
          - kind: LogQuery
            spec:
              plugin:
                kind: LokiLogQuery
                spec:
                  query: '{deployment_environment=~"$env", service_name=~"$service"}'
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 24
            height: 10
            content:
              $ref: "#/spec/panels/logs"
```

Apply it with `percli apply -f dashboard-explorer.yaml` and open `http://perses.localtest.me:8080/projects/inventory/dashboards/explorer`. Both dropdowns start at `All`, and the log table shows lines of both services. Remove `production` from the environment dropdown so that only `staging` is left: the service list shrinks to `checkout`.

## The matcher uses `=~`

The second variable has `deployment_environment=~"$env"` in its matcher. With one selected environment the text is `deployment_environment=~"staging"`; with two it is `deployment_environment=~"(production|staging)"`. Both are valid. The matcher with `=` would only work for one value.

## What `All` writes

When the reader picks `All`, Perses does not list every value. It writes the `customAllValue` instead, which is why the variables above set `customAllValue: ".*"`. The matcher then reads `deployment_environment=~".*"`, which matches every value, and also values that appear after the list was loaded.

Without `customAllValue`, `All` writes every loaded value as one group, so the query text grows with the number of values. With `.*`, the text stays short.

The special value `$__all` as `defaultValue` makes the dropdown start at `All`. Use it only on a variable that has `allowAllValue: true`.

## Test the text by hand

Write the shapes by hand and send them through the proxy. These two prove that the matcher accepts many values and `.*`:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/label/service_name/values \
  --data-urlencode 'match[]=app_requests_total{deployment_environment=~"(production|staging)"}' -G | jq -r '.data[]'
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/label/service_name/values \
  --data-urlencode 'match[]=app_requests_total{deployment_environment=~".*"}' -G | jq -r '.data[]'
```

Both print `checkout` and `payments`. Change the first matcher to `deployment_environment=~"staging"` and only `checkout` comes back.

## Common pitfalls

> [!WARNING]
> - **`=` in the matcher of a dependent variable.** It works with one value and returns nothing with two.
> - **`All` without `customAllValue` on a variable with many values.** The query text grows with the number of values.
> - **Setting `defaultValue: "$__all"` on a variable without `allowAllValue`.** The variable has no `All` entry to start at.
