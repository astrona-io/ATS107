# Solution: Repair An Incident Dashboard That Hides Data

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks five things: the variable order and the `$env` in the service matcher, the service list for each environment, that each query uses both variables, that every panel returns data for two real pairs, and that no panel was removed.

Start the port-forward in a second terminal, log in and select the project before the first step:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

Save the dashboard to a file so you can edit it:

```sh
percli describe dashboard incident > dashboard-incident.yaml
```

## Step 1: The service list ignores the environment

Read the variables in their order:

```sh
percli describe dashboard incident -o json | jq -c '.spec.variables[] | {name: .spec.name, matchers: .spec.plugin.spec.matchers}'
```

Two faults show at once. `service` comes before `env`, and its matcher is plain `app_requests_total`, without `$env`. So the list holds every service of every environment. In `dashboard-incident.yaml`, move the whole `env` entry above the `service` entry, and change the matcher of `service` to:

```yaml
matchers:
  - app_requests_total{deployment_environment="$env"}
```

## Step 2: The logs query uses a label Loki does not have

The `logs` query is `{deployment_environment="$env", service="$service"}`. Test it with a real pair written in:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/loki/loki/api/v1/query_range \
  --data-urlencode 'query={deployment_environment="production", service="checkout"}' | jq '.data.result | length'
```

The answer is `0`. Loki's label is `service_name`. Change the query in the file to:

```yaml
query: '{deployment_environment="$env", service_name="$service"}'
```

## Step 3: The traces query looks at the wrong level

The `traces` query is `{resource.deployment.environment="$env" && span.service.name="$service"}`. The service name is an attribute of the resource that sent the spans, not of a single span. Test it:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/tempo/api/search \
  --data-urlencode 'q={resource.deployment.environment="production" && span.service.name="checkout"}' \
  | jq '.traces | length'
```

The answer is `0`. Change the query in the file to:

```yaml
query: '{resource.deployment.environment="$env" && resource.service.name="$service"}'
```

## Step 4: Apply and prove

Apply the edited dashboard:

```sh
percli apply -f dashboard-incident.yaml
```

If `percli apply` complains about fields Perses manages, such as the creation time, delete them from `metadata` and apply again. Then check the cascade for `staging`:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/label/service_name/values \
  --data-urlencode 'match[]=app_requests_total{deployment_environment="staging"}' | jq -c '.data'
```

The answer is `["checkout"]`. Run the logs and traces queries from the steps above again with the corrected labels; both now return data. Finally, open `http://perses.localtest.me:8080/projects/inventory/dashboards/incident` and try both environments.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add `$env` to the matcher but keep `service` first | `$env` has no value when the service list loads; the grader checks the order |
| Delete the empty panels | The grader checks that every original panel still exists |
| Hard-code `checkout` in the logs query | One pair works; the grader tests two pairs |
