# Use Built-In Variables And Choose Groupings

The variables you create yourself come from a list or from a backend query. Perses also provides variables you never define: the dashboard time range, the step of a chart and the names of the project and the dashboard. A query that uses them adapts to whatever window the reader picks. The same idea applies to the labels you group by: when the grouping is a variable, one panel answers many questions.

Keep one sentence in mind: **a query should never contain a number that depends on the window or on the question, because the reader can change both.** This module replaces fixed range selectors with built-in variables and fixed group-by labels with a variable.

The module has four parts. **Built-In Variables** lists them and builds a panel that follows the time range. **The Rate Interval** explains why `[5m]` breaks on some windows and what `$__rate_interval` does instead. **Variables That Choose A Grouping** builds a group-by selector, and ends with a graded lab. **Query Results As Variable Values** fills a list from a PromQL expression and shows how to find out why a list is empty.

## Learning objectives

After this module you can:

- Name the built-in variables and say what each one holds.
- Use `$__range` and `$__interval` in a query, and `$__rate_interval` in a `rate`.
- Build a variable that chooses the label a query groups by, for one or several values.
- Fill a variable from a label name list or a PromQL expression, and test the list through the proxy.

## Before you start

You need the dashboard model, dashboard variables and the formats `csv` and `regex`, and PromQL with `rate` and `sum by`.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** and the observability stack. The counter `app_requests_total` has the labels `service_name` (`checkout`, `payments`) and `deployment_environment` (`production`, `staging`). The project `inventory` and the global datasources `prometheus`, `loki`, `tempo` and `pyroscope` exist.

Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory` before you read on.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
