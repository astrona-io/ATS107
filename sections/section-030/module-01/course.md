# Make Dashboards Interactive With Variables

A dashboard is most useful when one reader can point it at their own service, environment or datasource without editing it. Perses does this with **variables**: named values the reader picks at the top of the dashboard, which queries use through `$name`. A variable is only as good as its values, and those values can come from a fixed list, from a backend query, or from the list of datasources.

This module builds variables of every common kind. Keep one sentence in mind: **a variable has a source for its values and a place where it is defined, and a query decides how the selected values are written into its text.** Each part handles one piece of that sentence.

The module has three parts. **List And Text Variables** covers the two variable kinds and the fields that control a list. **Variables Backed By Queries And Datasources** fills lists from Prometheus and Loki and lets the reader choose the datasource; a graded lab follows it. **Interpolation Formats And Variable Scopes** shows how several values become valid query text, and where else variables can live.

## Learning objectives

After this module you can:

- Write a `TextVariable` and a `ListVariable` with a static list.
- Control a list with `allowMultiple`, `allowAllValue`, `customAllValue`, `defaultValue`, `sort` and `capturingRegexp`.
- Fill a list from Prometheus label values or a PromQL query, and from Loki label values.
- Let the reader choose a datasource with a `DatasourceVariable`, and make queries use it.
- Choose the interpolation format that makes one or several values valid in a query.
- Predict which variable a dashboard uses when the same name exists at several scopes.

## Before you start

You need to read and write a Perses dashboard resource (panels, queries, layouts) and to apply it with `percli`. You also need PromQL label matchers: `=` for one value and `=~` for a regular expression.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses` and the backends in the namespace `observability`. Prometheus holds the counter `app_requests_total` with the labels `service_name` (`checkout`, `payments`) and `deployment_environment` (`production`, `staging`). Perses holds the project `inventory`, a default global datasource for each backend, and a second, non-default global Prometheus datasource, `prometheus-replica`, that reaches the same Prometheus. Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
