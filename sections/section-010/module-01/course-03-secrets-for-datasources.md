# Secrets For Datasource Credentials

The Loki gateway in the playground answers `401` to every request that comes without a user and a password. Many real backends do the same: a hosted Prometheus wants a token, a shared Loki wants basic authentication. Perses keeps such credentials in a separate resource, a **Secret**, so the datasource only holds a reference to it. This part creates a Secret, connects a datasource to it, and checks that the gateway now answers.

## Secret and GlobalSecret

A Secret is a Perses resource that holds credentials for a backend. Perses has two kinds, and the scope must match the datasource that uses it:

| Datasource | Secret it can use |
| --- | --- |
| `GlobalDatasource` | `GlobalSecret` |
| Project `Datasource`, or a datasource inside a dashboard | `Secret` in the same project |

A project datasource cannot use a `GlobalSecret`, and a global datasource cannot use a project `Secret`. The spec of both kinds holds one way to authenticate:

| Field | What it sends |
| --- | --- |
| `basicAuth` | A `username` and a `password` (or a `passwordFile`) as HTTP basic authentication |
| `authorization` | A `type` (default `Bearer`) and `credentials`, as an `Authorization` header |
| `oauth` | OAuth client credentials: `clientID`, `clientSecret`, `tokenURL` |
| `tlsConfig` | A certificate authority, a client certificate and key, a server name |

`basicAuth`, `authorization` and `oauth` exclude each other; use one. `tlsConfig` can sit next to any of them.

## Connect a datasource to a Secret

The gateway wants basic authentication with the lab-only user `perses` and the password `loki-gateway-password`. Create the Secret in the project `inventory`. Save this as `secret-gateway-demo.yaml`:

<!-- astrona:playground:renew -->

```yaml
kind: Secret
metadata:
  name: gateway-demo
  project: inventory
spec:
  basicAuth:
    username: perses
    password: loki-gateway-password
```

Apply it:

```sh
percli apply -f secret-gateway-demo.yaml
```

A datasource uses the Secret through the field `secret` in its proxy spec, which takes the Secret's name. Save this as `datasource-loki-demo.yaml`; it is a project datasource for the gateway with a different name from the global one, so nothing else changes:

```yaml
kind: Datasource
metadata:
  name: loki-demo
  project: inventory
spec:
  default: false
  plugin:
    kind: LokiDatasource
    spec:
      proxy:
        kind: HTTPProxy
        spec:
          url: http://loki-gateway.observability
          secret: gateway-demo
```

Apply it:

```sh
percli apply -f datasource-loki-demo.yaml
```

Then check the result. Ask for the label list through the new datasource and print the labels:

```sh
curl -s http://perses.localtest.me:8080/proxy/projects/inventory/datasources/loki-demo/loki/api/v1/labels \
  | jq -r '.data[]'
```

This time the gateway answers with the labels Loki knows, among them `service_name` and `deployment_environment`. The Perses server read the Secret, added the basic authentication header, and forwarded the request. Your `curl` request carried no password at all.

## Why not a header?

The proxy spec also has a `headers` field, and you could put an `Authorization` header there with the encoded password. Do not. A header in the datasource sits next to every other setting, so anyone who can read the datasource can read the password. A Secret is a separate resource, with its own permissions once authentication is on, and one Secret can serve several datasources. The graded lab rejects credentials in a header for that reason.

The resource files you write for a Secret still hold the password in plain text. Treat them as sensitive: keep them out of Git, or keep real passwords out of them.

## Restricting the new datasource

The datasource `loki-demo` has no `allowedEndpoints`, so the proxy forwards any path. The Loki plugin only reads: queries, labels, label values and series. A list that holds exactly those paths keeps the gateway's other paths out of reach:

```yaml
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

The list goes under `proxy.spec`, next to `url` and `secret`. With it in place, a request for `/loki/api/v1/status/buildinfo` is refused by the Perses server and never reaches the gateway.

You can now give a datasource its own credentials without writing them into the datasource, and limit what it forwards. What remains is to put the pieces together: override the global `loki` datasource for one project, with a Secret and a short endpoint list.

## Common pitfalls

> [!WARNING]
> - **A project datasource that references a `GlobalSecret`.** It cannot. Create a `Secret` in the same project.
> - **A wrong Secret name.** The field `secret` takes the name of the Secret, not of the user. A wrong name means no credentials, and the backend answers `401`.
> - **Credentials in `headers`.** They work, but anyone who can read the datasource can read them.
> - **Committing the Secret file with a real password.** The file holds it in plain text.

## Your mission: Give A Project Its Own Loki Datasource

You can now store credentials in a Secret, reference them from a datasource and restrict its proxy. The graded lab asks you to give the project `inventory` its own `loki` datasource that overrides the global one, sends the gateway credentials from a Secret, and forwards only the Loki read endpoints, without changing the global datasource.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-010-01
astrona start ats-107-playground-010-01
```
