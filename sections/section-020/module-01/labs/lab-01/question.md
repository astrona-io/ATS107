# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Panels per signal

## Scenario

The on-call team of `checkout` wants one dashboard they can open when an alert fires: request rates, the service's logs, its traces, and a CPU profile, all on one screen. Every backend is connected to Perses through a default global datasource: `prometheus`, `loki`, `tempo` and `pyroscope`.

## Your task

In the project `inventory`, create the dashboard `signals` with these four panels:

1. A `TimeSeriesChart` with a `PrometheusTimeSeriesQuery` that shows the request rate of `checkout`, from the counter `app_requests_total`.
2. A `LogsTable` with a `LokiLogQuery` that shows the logs of `checkout`.
3. A `TraceTable` with a `TempoTraceQuery` that searches the traces of `checkout`.
4. A `FlameChart` with a `PyroscopeProfileQuery` that shows the CPU profile (`process_cpu:cpu:nanoseconds:cpu:nanoseconds`) of the service `pyroscope`.

Place all four panels in a grid layout.

## Constraints

- Use the default global datasources; do not create new datasources.
- The label for the service is `service_name` in PromQL and LogQL, and the resource attribute `service.name` in TraceQL.

## Done when

- The dashboard `signals` has one panel of each kind above, each with the matching query plugin.
- Every panel is placed in the layout.
- Every panel's query returns data through the Perses proxy.
