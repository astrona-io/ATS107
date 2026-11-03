# Summary

A dashboard is more than its queries. This module tuned a time series chart, placed panels on a grid, set the time defaults and moved a dashboard to a file and back.

## What you learned

A `TimeSeriesChart` has five groups of settings. The `legend` has a `position`, a `mode` of `list` or `table`, and `values` for the table columns. The `yAxis` has a `format` with a unit, a `min` and a `max`. The `visual` group sets `display`, `lineWidth`, `areaOpacity`, `lineStyle`, `stack` and `connectNulls`. The `thresholds` group draws limit lines in the same form as on a stat chart. The `querySettings` group gives a colour to a query by its index.

Panels are defined once under `spec.panels` and placed under `spec.layouts`. A `Grid` has 24 columns, and each item has `x`, `y`, `width`, `height` and a `$ref` to the panel. A layout with `display.title` is a group, and `display.collapse.open` decides whether it starts open. A panel in no layout is never shown.

The dashboard fields `duration` and `refreshInterval` set the default window and refresh. The time picker and the URL parameters `start`, `end` and `refresh` change them for one view without changing the dashboard.

With `percli`, `get dashboard -o yaml` exports a dashboard, `lint -f` checks a file without a server, `apply -f` creates or replaces, and `delete dashboard` removes.

- Set the axis unit and `min: 0` on every rate chart.
- Put detail panels in a collapsed group, and the main panels in an open one.
- Share a window as a URL, not as an edit.
- Keep dashboards as files and lint them before you apply them.

<!-- astrona:playground:destroy -->
