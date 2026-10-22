# Solution: Give A Project Its Own Loki Datasource

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the project datasource `loki` exists and uses the Secret `loki-gateway-auth`, Loki answers through it, a path outside its endpoint list is refused, and the global `loki` datasource is unchanged.

## Step 1: Connect percli and see the problem

Start the port-forward in a second terminal, then log in and select the project:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

Ask the gateway for its labels through the global datasource, and print the status code:

```sh
curl -s -o /dev/null -w '%{http_code}\n' \
  http://perses.localtest.me:8080/proxy/globaldatasources/loki/loki/api/v1/labels
```

The status is `401`. The path is on the global datasource's endpoint list, so Perses forwarded the request, and the gateway refused it: the global datasource sends no credentials.

## Step 2: Create the Secret

Save this as `secret-loki-gateway-auth.yaml`:

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

The Secret is a project `Secret`, because the datasource that uses it is a project `Datasource`. A `GlobalSecret` would not work here.

## Step 3: Create the project datasource

The datasource gets the same name as the global one, so every dashboard in `inventory` that asks for `loki` now uses it: the smallest scope wins. Save this as `datasource-loki.yaml`:

```yaml
kind: Datasource
metadata:
  name: loki
  project: inventory
spec:
  default: true
  plugin:
    kind: LokiDatasource
    spec:
      proxy:
        kind: HTTPProxy
        spec:
          url: http://loki-gateway.observability
          secret: loki-gateway-auth
          allowedEndpoints:
            - endpointPattern: /loki/api/v1/query
              method: GET
            - endpointPattern: /loki/api/v1/query_range
              method: GET
            - endpointPattern: /loki/api/v1/labels
              method: GET
            - endpointPattern: /loki/api/v1/label/([a-zA-Z0-9_-]+)/values
              method: GET
            - endpointPattern: /loki/api/v1/series
              method: GET
```

Apply it:

```sh
percli apply -f datasource-loki.yaml
```

## Step 4: Prove the result

Ask for the labels through the project datasource:

```sh
curl -s http://perses.localtest.me:8080/proxy/projects/inventory/datasources/loki/loki/api/v1/labels \
  | jq -r '.data[]'
```

The list now holds the labels Loki knows, among them `service_name`. Then try a path that is not on the list:

```sh
curl -s -o /dev/null -w '%{http_code}\n' \
  http://perses.localtest.me:8080/proxy/projects/inventory/datasources/loki/loki/api/v1/status/buildinfo
```

The status is not `200`: the Perses server refused the request before it reached the gateway. Finally, confirm the global datasource is untouched:

```sh
percli describe gdts loki
```

It still points at the gateway with no `secret`, exactly as before.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add the Secret to the global datasource | Every project now sends this project's gateway password; the grader checks the global datasource is unchanged |
| Put an `Authorization` header in the proxy | It works, but the password sits in the datasource for anyone who can read it; the grader rejects it |
| Leave out `allowedEndpoints` | The proxy forwards every gateway path; the grader requests a path outside the list |
| Name the datasource `loki-inventory` | Dashboards that ask for `loki` still use the global one and stay empty |

## Common mistakes

- Creating a `GlobalSecret` for a project datasource. Only a project `Secret` works.
- Writing the endpoint patterns without the `/loki` prefix. The gateway serves Loki's paths as they are.
- Testing with the global proxy path after the change. The override only shows on the project path, and in dashboards of `inventory`.

## Practice on your own

- Create a second project, open a Loki panel there, and confirm it still uses the global datasource.
- Remove `/loki/api/v1/series` from the list and find which part of the Perses user interface stops working.
