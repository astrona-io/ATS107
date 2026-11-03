# Tune Time Series, Layouts And Dashboard Files

A `TimeSeriesChart` with default settings is a good start, and a poor finished panel. The legend covers half the chart, the axis shows raw numbers, nothing marks the limit, and the dashboard around it has no order. This module teaches the settings that turn a first chart into a panel an on-call engineer can read in two seconds, and then the parts of the dashboard that hold the panels together: the grid, the panel groups, the time range and the refresh interval.

The last part treats a dashboard as a file. Everything you build in the user interface can be exported, kept next to the code, checked and applied again, and that is how a team runs dashboards in practice.

The module has four parts. **Time Series Chart Options** covers the legend, the axis, the line style and the thresholds. **Grid Layouts And Panel Groups** covers the 24-column grid and collapsible groups. **Time Range And Refresh** covers the dashboard duration, the refresh interval and the built-in range variables. **Dashboards As Files** covers `percli get`, `apply`, `lint` and `delete`, and ends with a graded lab.

## Learning objectives

After this module you can:

- Set the legend, the y axis, the line style and the thresholds of a `TimeSeriesChart`.
- Place panels on the grid with `x`, `y`, `width` and `height`, and group them under collapsible titles.
- Set the default time range and refresh interval of a dashboard, and say how the URL overrides them.
- Export, check, apply and delete a dashboard with `percli`.

## Before you start

You need the dashboard model, the `TimeSeriesChart` panel, PromQL with `rate` and `sum by`, and the single-number panels.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** and the observability stack. The counter `app_requests_total` has the labels `service_name` (`checkout`, `payments`) and `deployment_environment` (`production`, `staging`). The project `inventory` and the global datasources `prometheus`, `loki`, `tempo` and `pyroscope` exist.

Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory` before you read on.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
