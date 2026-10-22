# Summary

A Perses dashboard can show metrics, logs, traces and profiles side by side, and every panel follows the same pattern. This module built one panel per signal and showed how to tell an empty query from a broken panel.

## What you learned

A dashboard resource has `panels`, a map of named panels, and `layouts`, which place them. Each panel has a panel plugin that draws, and a list of `queries`. Each query has a kind, which must fit the panel, and a query plugin, which fetches the data from one kind of backend. A query without a `datasource` uses the default datasource of the kind its plugin needs. A layout of kind `Grid` places panels with `x`, `y`, `width` and `height` on 24 columns, and points at each panel with a `$ref` such as `#/spec/panels/requests`. A panel no layout points at never appears.

The four signals use four pairs of plugins. Metrics from Prometheus are a `TimeSeriesChart` with `PrometheusTimeSeriesQuery`. Logs from Loki are a `LogsTable` with `LokiLogQuery`, and a count of log lines is a `TimeSeriesChart` with `LokiTimeSeriesQuery`. Traces from Tempo are a `TraceTable` with `TempoTraceQuery`; a `ScatterChart` shows trace durations and a `TracingGanttChart` shows the spans of one trace. Profiles from Pyroscope are a `FlameChart` with `PyroscopeProfileQuery`, which needs a profile type and a service.

The same labels carry different names in each query language. The OpenTelemetry attribute `service.name` is the label `service_name` in PromQL and LogQL, and `resource.service.name` in TraceQL. Perses checks the shape of a dashboard when you apply it, but not whether a label or a datasource exists, so a query can be valid and still return nothing. Sending the query through the Perses proxy with `curl` shows whether the problem is the query, the datasource or the panel.

- A panel plugin draws; a query plugin fetches; their kinds must fit.
- Every panel needs a layout item with a `$ref`.
- `service.name` is `service_name` in PromQL and LogQL, `resource.service.name` in TraceQL.
- Test a query through the proxy before you blame the panel.

<!-- astrona:playground:destroy -->
