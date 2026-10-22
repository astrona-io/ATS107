# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Datasources, the proxy and Secrets

## Scenario

The logs of the project `inventory` sit behind `loki-gateway`, an nginx proxy in front of Loki that asks for basic authentication. The platform team runs a global `loki` datasource for all projects, but it carries no credentials, so every Loki panel in `inventory` stays empty and the gateway answers `401`. The platform team does not want the global datasource changed. Other projects use it.

The gateway's lab-only credentials are the user `perses` and the password `loki-gateway-password`. The gateway's address inside the cluster is `http://loki-gateway.observability`.

## Your task

In the project `inventory`:

1. Create a `Secret` named `loki-gateway-auth` with the gateway credentials as basic authentication.
2. Create a `Datasource` named `loki` (the same name as the global one) of kind `LokiDatasource` that is the default for its kind, points at the gateway, and takes its credentials from `loki-gateway-auth`.
3. Limit the new datasource's proxy to the Loki read endpoints: `GET` on `/loki/api/v1/query`, `/loki/api/v1/query_range`, `/loki/api/v1/labels`, `/loki/api/v1/label/<name>/values` and `/loki/api/v1/series`.

## Constraints

- Do not change or delete the `GlobalDatasource` named `loki`.
- Do not put credentials in a proxy header; use the Secret.
- Keep `allowedEndpoints` on the project datasource.

## Done when

- `/proxy/projects/inventory/datasources/loki/loki/api/v1/labels` answers with a label list that contains `service_name`.
- `/proxy/projects/inventory/datasources/loki/loki/api/v1/status/buildinfo` is refused.
- The global `loki` datasource is exactly as it was.
