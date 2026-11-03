# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Variables and scopes

## Scenario

The dashboard `rates` of the project `inventory` has one panel, `requests`. Its query uses a fixed window of `[5m]` and always groups by `service_name`. On a window of a week the line misses short spikes, and the team also wants to look at the same rate by environment without a second panel.

## Your task

Change the dashboard `rates` so that:

1. A variable named `groupby` lets the reader choose between the labels `service_name` and `deployment_environment`. It shows the readable names `Service` and `Environment`, allows one value, and starts at `service_name`.
2. The query of the panel `requests` groups by the picked label and uses the built-in rate interval instead of a fixed window.

## Constraints

- Keep the panel `requests`; change its query, do not replace the panel.
- Use the default global datasource; do not create new datasources.
- The query must still be a rate of the counter `app_requests_total`.

## Done when

- `groupby` is a `ListVariable` with a `StaticListVariable` that holds both labels, with the display names above, and the default value `service_name`.
- The panel query uses `$groupby` (or `${groupby}`) in its `by` list and `$__rate_interval` as its range, and no fixed `[5m]` is left.
- With either label written in, the query returns data through the Perses proxy, and the panel `requests` is still in the layout.
