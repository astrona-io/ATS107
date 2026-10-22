# Summary

Variables turn one dashboard into many: the reader picks an environment, a service or a datasource, and every query follows. This module showed the kinds of variables, where their values come from, how a value is written into a query, and where a variable can be defined.

## What you learned

A dashboard variable is an entry in `spec.variables`. A `TextVariable` holds a free text value, fixed when `constant` is set. A `ListVariable` is a dropdown whose values come from a variable plugin. Its behaviour is set by a few fields: `allowMultiple` for several values, `allowAllValue` and `customAllValue` for an `All` entry, `defaultValue` for the first selection, `sort` for the order, and `capturingRegexp` to keep only matching values.

The values can come from a `StaticListVariable` you write yourself, or from a backend. A `PrometheusLabelValuesVariable` lists the values of a label on the series that match its `matchers`; a `PrometheusPromQLVariable` takes them from the result of a PromQL expression; a `LokiLabelValuesVariable` does the same for log streams. A `DatasourceVariable` lists the datasources of one plugin kind, and queries and other variables follow the choice when their `datasource` is `$name`. Perses resolves variables in list order, so a variable that others use comes first.

A query names a variable as `$name`, `${name}` or `${name:format}`. One selected value is written as it is; several values use the `prometheus` format, a regular expression group, which fits `=~` in PromQL, LogQL and TraceQL alike. Other formats such as `csv`, `json`, `lucene` or `queryparam` fit other places. Like datasources, variables exist at three scopes, dashboard, project `Variable` and `GlobalVariable`, and the smallest scope wins when names are equal.

- Several values need `=~`, never `=`.
- A variable that other variables use comes first in the list.
- A query follows a `DatasourceVariable` only when its `datasource` is `$name`.
- A project `Variable` hides a `GlobalVariable` of the same name.

<!-- astrona:playground:destroy -->
