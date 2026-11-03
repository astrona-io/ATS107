# Show Single Numbers, Gauges And Bars

A time series chart answers "how did this change?". Many questions on an operations dashboard are simpler: how many requests per second right now, which service is busiest, is this value above the limit. Perses has panel plugins built for those questions, and each one shares the same small set of settings: a calculation, a format and thresholds.

This module teaches those panels with one running example, the counter `app_requests_total`. Keep one sentence in mind: **a query returns series, the panel plugin reduces each series to one number with a calculation, and the format and thresholds decide how that number is written and coloured.**

The module has four parts. **Stat Charts, Calculations And Units** builds a `StatChart` and explains the three shared settings. **Gauges And Thresholds** adds a `GaugeChart` and shows how threshold steps and percent units work. **Bar Charts, Pie Charts And Tables** compares series, and ends with a graded lab. **Markdown Panels And Instant Queries** adds explanatory text and a `Table` fed by an instant query.

## Learning objectives

After this module you can:

- Build a `StatChart`, a `GaugeChart` and a `BarChart` on a PromQL query.
- Choose a `calculation` that reduces a series to one number, and say what each choice returns.
- Set a unit with `format.unit` and pick between `percent` and `percent-decimal`.
- Write `thresholds` with an `absolute` or a `percent` mode.
- Use a `Markdown` panel for text, and an instant query for a `Table`.

## Before you start

You need the dashboard model (panels, queries, layouts), the `TimeSeriesChart` panel and PromQL with `rate` and `sum by`.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** and the observability stack. The counter `app_requests_total` has the labels `service_name` (`checkout`, `payments`) and `deployment_environment` (`production`, `staging`). The project `inventory` and the global datasources `prometheus`, `loki`, `tempo` and `pyroscope` exist.

Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory` before you read on.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
