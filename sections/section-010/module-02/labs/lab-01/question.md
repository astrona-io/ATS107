# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Datasources

## Scenario

The reporting team in the project `inventory` has a dashboard `reports`. Its panel asks for a Prometheus datasource named `reports-prometheus`, but that datasource does not exist at any scope, so the panel stays empty. The team wants the datasource to belong to the dashboard only, because no other dashboard should be able to use it.

## Your task

Change the dashboard `reports` so that:

1. It defines a datasource named `reports-prometheus` of kind `PrometheusDatasource` in its own `spec.datasources`.
2. The datasource forwards queries through the Perses proxy to `http://prometheus.observability:9090` and is not the default datasource.
3. The datasource sets `scrapeInterval` to `30s`.

## Constraints

- Do not create a project `Datasource` or a `GlobalDatasource` with the name `reports-prometheus`.
- Keep the panel `requests` and its query exactly as they are, including the datasource name it uses.
- Do not change the global datasource `prometheus`.

## Done when

- `/proxy/projects/inventory/dashboards/reports/datasources/reports-prometheus/api/v1/query` answers a query for `up` with at least one series.
- The dashboard defines the datasource with the settings above.
- No project or global datasource has the name `reports-prometheus`.
