# Solution: Make A Rate Dashboard Adapt To Its Window

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the dashboard has a `groupby` list variable with both labels and the right default; the panel query uses `$groupby` and `$__rate_interval` with no fixed window; and the query returns data when each label is written in.

## Step 1: Connect percli and export the dashboard

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
percli get dashboard rates -o yaml > dashboard-rates.yaml
```

## Step 2: Test both groupings first

Built-in variables do not exist outside a dashboard, so test with a fixed window. Both counts must be 2:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total[5m]))' | jq '.data.result | length'
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (deployment_environment) (rate(app_requests_total[5m]))' | jq '.data.result | length'
```

## Step 3: Edit the file

In `dashboard-rates.yaml`, replace `variables: []` with the variable, and change the query. Keep the `metadata` block the server wrote:

```yaml
  variables:
    - kind: ListVariable
      spec:
        name: groupby
        display:
          name: Group by
          hidden: false
        allowAllValue: false
        allowMultiple: false
        defaultValue: service_name
        plugin:
          kind: StaticListVariable
          spec:
            values:
              - value: service_name
                label: Service
              - value: deployment_environment
                label: Environment
```

The query of the panel `requests` becomes:

```yaml
                  query: sum by ($groupby) (rate(app_requests_total[$__rate_interval]))
```

## Step 4: Check and apply

```sh
percli lint -f dashboard-rates.yaml
percli apply -f dashboard-rates.yaml
```

Open `http://perses.localtest.me:8080/projects/inventory/dashboards/rates`, switch `Group by`, and watch the lines change.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep `[5m]` and only add the variable | The task asks for the rate interval; the grader rejects a fixed window |
| Put the labels in `value` and `label` the other way round | The query receives `Service`, which is not a label, and returns no data |
| Set `allowAllValue: true` | `All` is not a label name, so the query fails |
