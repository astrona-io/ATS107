# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Unified incident dashboard

## Scenario

The on-call engineers of the project `inventory` want one dashboard to open when an alert fires. They pick the environment, then the service, and see the request rate, the logs and the traces of that service in that environment. The service list must only offer services that really run in the selected environment: `checkout` runs in `production` and `staging`, `payments` only in `production`.

Every backend has a default global datasource: `prometheus`, `loki` and `tempo`.

## Your task

In the project `inventory`, create the dashboard `incident` with:

1. A variable `env` that lists the values of the Prometheus label `deployment_environment` on `app_requests_total`.
2. A variable `service` that lists the values of the Prometheus label `service_name` on `app_requests_total`, but only for the environment selected in `env`.
3. A metrics panel (`TimeSeriesChart` with `PrometheusTimeSeriesQuery`), a logs panel (`LogsTable` with `LokiLogQuery`) and a traces panel (`TraceTable` with `TempoTraceQuery`), each showing only data of the selected environment and service.

Place all panels in a grid layout.

## Constraints

- Use the default global datasources.
- Both variables are single-value lists read from Prometheus label values.

## Done when

- `env` comes before `service`, and the matcher of `service` uses `$env`.
- For `staging`, the service list holds only `checkout`; for `production`, it holds `checkout` and `payments`.
- Each of the three queries uses `$env` and `$service`, and returns data for `production`/`payments` and for `staging`/`checkout`.
