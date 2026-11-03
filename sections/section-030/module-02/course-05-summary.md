# Summary

Queries that contain fixed numbers and fixed labels answer one question. This module replaced them with variables so that one panel follows the reader's window and the reader's choice of grouping.

## What you learned

Perses defines built-in variables in every dashboard. `$__interval` and `$__interval_ms` hold the step of the chart. `$__range`, `$__range_s` and `$__range_ms` hold the length of the time range. `$__rate_interval` holds a window for `rate` that is never shorter than four scrape intervals, and `$__project` and `$__dashboard` hold the project and dashboard names. Built-in variables exist inside a dashboard only; a query you test with `curl` needs a real duration in their place.

A fixed `[5m]` in `rate` breaks when the scrape interval is long or the chart covers a long range. `$__rate_interval` follows both. Use `$__interval` in functions such as `avg_over_time`, and `$__range` when the answer is one number for the whole window.

A `StaticListVariable` with `value` and `label` pairs can choose the label a query groups by. For several labels, set `allowMultiple` and write `${name:csv}`. A `PrometheusLabelNamesVariable` reads label names from Prometheus. A `PrometheusPromQLVariable` fills a list from the labels of an expression and changes with the data.

- Replace every fixed range selector on a chart with `$__rate_interval`.
- Use `${name:csv}` for group-by lists.
- Keep `allowAllValue` off on a variable that holds label names.
- When a list is empty, run the expression by hand, then check the label, the datasource and the order.

<!-- astrona:playground:destroy -->
