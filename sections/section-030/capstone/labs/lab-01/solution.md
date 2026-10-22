# Solution: Fix Variables That Show The Wrong Values

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the `env` values the project gets are `production` and `staging` while the `GlobalVariable` is unchanged, the `service` variable lists the right services, and the panel query works with two services.

Start the port-forward in a second terminal, log in and select the project before the first step:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Step 1: Find where `env` comes from

The dashboard itself has no variable named `env`; read it to confirm:

```sh
percli describe dashboard overview -o json | jq -r '.spec.variables[].spec.name'
```

Only `service` is listed, so `env` comes from a larger scope. List both:

```sh
percli get gv
percli get var
```

There is a `GlobalVariable` named `env` and a project `Variable` named `env`. The project one wins for every dashboard of `inventory`. Read both:

```sh
percli describe gv env
percli describe var env
```

The global list holds `production` and `staging`; the project list holds `prod` and `stage`, an old override that no longer matches the data.

## Step 2: Remove the stale override

The global list is right, so the project override only hides it. Delete it:

```sh
percli delete var env
```

The dashboards of `inventory` now get the `GlobalVariable`. Fixing the values of the project `Variable` instead would also pass, but it keeps a second list that someone must keep in step with the global one.

## Step 3: Fix the service variable and the query

Save the dashboard to a file:

```sh
percli describe dashboard overview > dashboard-overview.yaml
```

Two things are wrong in it. The `service` variable reads the label `service`, which does not exist; the label is `service_name`. The panel query matches `service_name="$service"`, which breaks as soon as two services are selected. In `dashboard-overview.yaml`, set the variable's `labelName` to `service_name`, and change the query to:

```yaml
query: sum by (service_name) (rate(app_requests_total{deployment_environment="$env", service_name=~"$service"}[5m]))
```

The matcher of the `service` variable, `app_requests_total{deployment_environment="$env"}`, is already right: it limits the services to the selected environment. Apply the file:

```sh
percli apply -f dashboard-overview.yaml
```

If `percli apply` complains about fields Perses manages, such as the creation time, delete them from `metadata` and apply again.

## Step 4: Prove the result

List the services of `production`, the way the `service` variable does:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/label/service_name/values \
  --data-urlencode 'match[]=app_requests_total{deployment_environment="production"}' | jq -c '.data'
```

The answer is `["checkout","payments"]`. Then run the panel query with both services written in:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total{deployment_environment="production", service_name=~"(checkout|payments)"}[5m]))' \
  | jq '.data.result | length'
```

The answer is `2`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change the `GlobalVariable` to `prod` and `stage` | Every project gets values that match no data; the grader checks the global variable is unchanged |
| Add a dashboard variable `env` | It hides the problem in one dashboard; every other dashboard of `inventory` still gets `prod` and `stage` |
| Turn off `allowMultiple` | The panel works with one service only; the task asks for several |
| Rename the label in Prometheus | The label comes from the telemetry; fix the variable, not the data |
