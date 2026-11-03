# Summary

Single-number panels turn a query into a value a reader can check at a glance. This module built a stat chart, a gauge, a bar chart, a Markdown panel and a table on the same counter, and showed the three settings they share.

## What you learned

A query returns series, and a single-number panel reduces each series to one value with a `calculation`: `first`, `last`, `first-number`, `last-number`, `mean`, `sum`, `min` or `max`. The `format` object writes the value with a `unit` and a number of `decimalPlaces`. A unit changes the text and never the query. The unit `percent` expects values from 0 to 100, and `percent-decimal` expects values from 0 to 1. The `thresholds` object colours the value: a `defaultColor` for values below the first step, and steps that apply from their `value` upward. The mode `absolute` compares the value as it is, and the mode `percent` compares it with a percentage of `max`.

A `GaugeChart` needs a `max` when its unit is not a percentage. A `BarChart` draws one bar for each series, so its query must return several series, and `seriesNameFormat` gives the bars readable names. A `PieChart` shows how parts divide a whole and works best with few parts.

A `Markdown` panel holds static text and uses no query. An instant query, set with `instant: true`, returns one value for each series instead of a list of points, and a `Table` shows those values as rows.

- Pick the panel by the question: value now, distance to a limit, comparison, share, change over time.
- Rates need `rate` on counters before any comparison.
- Write thresholds from the lowest value to the highest.
- Test the query through the proxy before you build the panel.

<!-- astrona:playground:destroy -->
