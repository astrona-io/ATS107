# Section 020: Metrics, Logs, Traces And Profiles

When an incident starts, the question moves from one signal to the next. A graph of request rates shows *that* something is wrong, the logs show *what* went wrong, a trace shows *where* in the call chain it happened, and a profile shows *which code* used the time. Perses can show all four signals on one dashboard, but each one needs its own panel plugin and its own query plugin.

This section builds that dashboard one signal at a time. It starts with the dashboard model itself, because every panel follows the same pattern: a panel plugin that draws, a query plugin that fetches, and a layout that places the panel on the grid.

**Topic covered:** Panels per signal

## What you will learn

- The parts of a dashboard resource: `panels`, `queries`, `layouts` and the `$ref` that places a panel.
- A time series panel for Prometheus with `TimeSeriesChart` and `PrometheusTimeSeriesQuery`.
- A log panel for Loki with `LogsTable` and `LokiLogQuery`, and a log rate with `LokiTimeSeriesQuery`.
- A trace panel for Tempo with `TraceTable` and `TempoTraceQuery`, and when to use `TracingGanttChart` and `ScatterChart`.
- A flame graph for Pyroscope with `FlameChart` and `PyroscopeProfileQuery`.
- How to test any panel's query through the Perses proxy before you blame the panel.

## The learning path

The section has one module with a landing page, three parts, a graded lab right after the third part, and a summary. The landing page starts the module's playground.

### 1. Show Metrics, Logs, Traces And Profiles

The playground holds Perses with a default global datasource for each backend, and telemetry for `checkout` and `payments`.

1. Metrics Panels And The Dashboard Model
2. Logs From Loki
3. Traces From Tempo And Profiles From Pyroscope, followed by the lab **Build A Dashboard For Four Signals**
4. Summary

## Section capstone: Repair A Dashboard That Shows Nothing

The capstone is one graded scenario that combines the module. The dashboard `signals` of the project `inventory` was copied from another team and shows almost nothing. Each empty panel has a different cause. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-107-capstone-020
```
