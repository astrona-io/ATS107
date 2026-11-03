# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Panels

## Scenario

The platform team wants one screen that answers three questions about the services in the project `inventory`: how many requests per second arrive in total, how large is the share of `checkout` in that traffic, and which service is busiest. All metrics come from the counter `app_requests_total` in the default global datasource `prometheus`.

## Your task

In the project `inventory`, create the dashboard `numbers` with these three panels:

1. A `StatChart` with a `PrometheusTimeSeriesQuery` that shows the total request rate of all services. Its unit is `requests/sec`.
2. A `GaugeChart` that shows the share of `checkout` in the total request rate as a value between 0 and 1. Its unit is `percent-decimal`. It has `thresholds` with a `defaultColor` and at least two steps, written from the lowest value to the highest.
3. A `BarChart` that shows the request rate of each service, one bar for each value of `service_name`. Its unit is `requests/sec`, and the bars are sorted from the highest to the lowest.

Place all three panels in a grid layout.

## Constraints

- Use the default global datasource; do not create new datasources.
- Use `rate` on the counter in every query.
- Do not use a fixed value in place of a query.

## Done when

- The dashboard `numbers` has one panel of each kind above with the units above.
- The gauge has the thresholds above and the bar chart is sorted from the highest to the lowest.
- Every panel is placed in the layout.
- Every query returns data through the Perses proxy, and the bar chart's query returns one series for each service.
