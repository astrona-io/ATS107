# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Datasources, the proxy and Secrets

## Scenario

Since a change last night, every dashboard of the project `inventory` is empty. Metrics, logs and traces are all gone, but the backends are healthy: the telemetry still arrives in Prometheus, Loki and Tempo. Three datasources the project relies on were changed, each in a different way.

The project uses the global datasource `prometheus`, and its own project datasources `loki` (through `loki-gateway`, lab-only user `perses`, password `loki-gateway-password`) and `tempo`. The backends are at `http://prometheus.observability:9090`, `http://loki-gateway.observability` and `http://tempo.observability:3200`.

## Your task

Find the fault in each of the three datasources and fix it, so that:

1. A PromQL query through the global datasource `prometheus` returns data.
2. A LogQL query through the project datasource `loki` returns the logs of `checkout`.
3. A TraceQL search through the project datasource `tempo` returns traces of `checkout`.

## Constraints

- Repair the datasources; do not delete them. `loki` and `tempo` stay project datasources.
- `loki` keeps using the Secret `loki-gateway-auth`; do not put credentials in a header.
- `tempo` keeps an `allowedEndpoints` list. Allow what trace search and trace lookup need, and nothing more: `/api/status/buildinfo` must stay refused.

## Done when

- `up` returns series through `/proxy/globaldatasources/prometheus`.
- `{service_name="checkout"}` returns log streams through `/proxy/projects/inventory/datasources/loki`.
- `{resource.service.name="checkout"}` returns traces through `/proxy/projects/inventory/datasources/tempo`, and `/api/status/buildinfo` is refused there.
