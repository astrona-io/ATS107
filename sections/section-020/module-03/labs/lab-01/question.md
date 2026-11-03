# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Dashboards

## Scenario

The project `inventory` has a dashboard `traffic` with one panel, `rate`, that shows the request rate of each service. It works, but the on-call team cannot read it: the legend only names the lines, the axis has no unit, nothing marks the limit of 10 requests per second, and the dashboard opens on the last hour and never refreshes. The team also wants the split by environment, without crowding the first screen.

## Your task

Change the dashboard `traffic` in the project `inventory`:

1. Tune the panel `rate`. Its legend is on the right as a table that shows the values `last` and `max`. Its y axis uses the unit `requests/sec` and starts at 0. The line has an area under it (`areaOpacity` above 0). It has `thresholds` in `absolute` mode with a step at the value 10.
2. Add a panel `by-env`, a `TimeSeriesChart` that shows the request rate of each value of `deployment_environment`, from the counter `app_requests_total`.
3. Place `by-env` in a second `Grid` layout with the title `Details` that starts closed.
4. Set the default window of the dashboard to `6h` and its refresh interval to `30s`.

## Constraints

- Keep the panel `rate`, its query and its place in the first layout; repair it, do not replace it with a new panel.
- Use the default global datasource; do not create new datasources.
- Use `rate` on the counter in every query.

## Done when

- The panel `rate` has the legend, axis, area and threshold settings above.
- The panel `by-env` exists, returns one series for each environment, and is in the second layout, which has the title `Details` and starts closed.
- The dashboard has `duration: 6h` and `refreshInterval: 30s`.
- The panel `rate` is still in the first layout, and every query returns data through the Perses proxy.
