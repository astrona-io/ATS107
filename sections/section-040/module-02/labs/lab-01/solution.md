# Solution: Filter Logs And Traces By Several Selections

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the four variables exist with the right settings and order; the log and trace queries use the variables with matchers that take several values; and every query returns data for `All`, for several values and for one value, with the service list following the environment.

## Step 1: Connect percli and export the dashboard

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
percli get dashboard explorer -o yaml > dashboard-explorer.yaml
```

## Step 2: Test the query shapes first

Write the values by hand. The service list for `staging` has one entry, and the log and trace counts are above zero:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/label/service_name/values \
  --data-urlencode 'match[]=app_requests_total{deployment_environment=~"staging"}' | jq -r '.data[]'
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/loki/loki/api/v1/query_range \
  --data-urlencode 'query={deployment_environment=~"(production|staging)", service_name=~"(checkout|payments)"} |= "order"' | jq '.data.result | length'
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/tempo/api/search \
  --data-urlencode 'q={resource.deployment.environment =~ ".*" && resource.service.name =~ ".*" && duration > 0ms}' | jq '.traces | length'
```

## Step 3: Edit the file

In `dashboard-explorer.yaml`, replace `variables: []` with the four variables. Keep the `metadata` block the server wrote:

```yaml
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
    - kind: TextVariable
      spec:
        name: search
        display:
          name: Search
          hidden: false
        value: order
        constant: false
    - kind: ListVariable
      spec:
        name: slower
        display:
          name: Slower than
          hidden: false
        allowAllValue: false
        allowMultiple: false
        defaultValue: 0ms
        plugin:
          kind: StaticListVariable
          spec:
            values:
              - value: 0ms
                label: Any duration
              - value: 10ms
                label: 10 milliseconds
              - value: 100ms
                label: 100 milliseconds
              - value: 1s
                label: 1 second
```

The query of the panel `logs` becomes:

```yaml
                  query: '{deployment_environment=~"$env", service_name=~"$service"} |= "$search"'
```

The query of the panel `traces` becomes:

```yaml
                  query: '{resource.deployment.environment =~ "$env" && resource.service.name =~ "$service" && duration > $slower}'
```

## Step 4: Check and apply

```sh
percli lint -f dashboard-explorer.yaml
percli apply -f dashboard-explorer.yaml
```

Open `http://perses.localtest.me:8080/projects/inventory/dashboards/explorer`, clear `production` from the environment dropdown, and check that the service list shrinks to `checkout`.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Use `=` in the matchers | A single value works and two values match nothing |
| Leave out `customAllValue` | `All` writes every loaded value, and the grader requires the text `.*` |
| Put `service` before `env` | The variable names `$env` before it exists |
