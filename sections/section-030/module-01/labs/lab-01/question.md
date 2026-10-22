# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Variables and scopes

## Scenario

The dashboard `services` of the project `inventory` has one panel, `requests`, and it only ever shows `checkout`, because the service is written into the query. The team also runs a second Prometheus datasource, `prometheus-replica`, and wants to switch the dashboard between the two without editing it.

## Your task

Change the dashboard `services` so that:

1. A variable named `prometheus` lets the reader pick any datasource of kind `PrometheusDatasource`.
2. A variable named `service` lists the values of the label `service_name` on `app_requests_total`, read from the datasource picked in `prometheus`, and lets the reader pick several services at once.
3. The query of the panel `requests` uses the picked datasource and shows the request rate of every picked service.

## Constraints

- Keep the panel `requests`; change its query, do not replace the panel.
- Do not create or change datasources.

## Done when

- `prometheus` is a `DatasourceVariable` for `PrometheusDatasource` and comes before `service`.
- `service` is a multi-value `PrometheusLabelValuesVariable` on `service_name` with `datasource: $prometheus`.
- The panel query uses `datasource: $prometheus` and matches `service_name` with `=~` and `$service`, and returns data for `checkout` and `payments` together.
