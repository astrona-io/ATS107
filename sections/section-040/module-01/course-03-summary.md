# Summary

An incident dashboard asks two questions once, the environment and the service, and every panel answers for exactly that pair. This module built the two parts that make it work: a service list that follows the environment, and one selection written correctly into three query languages.

## What you learned

A cascade is a variable whose values depend on another variable. The `service` variable reads Prometheus label values with the matcher `app_requests_total{deployment_environment="$env"}`, so it only lists the services of the selected environment. Perses works through the variable list in order, writes each selected value into the variables after it, and reloads them when the reader changes a value. A variable must therefore come after every variable it uses. The quickest test of a cascade is the label values call itself, with the parent's value written in by hand.

The same two OpenTelemetry attributes carry the environment and the service in every signal, but each backend names them its own way. Prometheus and Loki use the labels `deployment_environment` and `service_name`, with underscores; Tempo uses `resource.deployment.environment` and `resource.service.name`, with dots and the level in front. PromQL and LogQL join matchers with a comma; TraceQL joins conditions with `&&`. Each query goes into the panel for its signal, and without a `datasource` field each uses the default datasource of its kind.

When one panel stays empty while the others show data, the selection reached it and its query names a label its backend does not have. Writing the values in by hand and sending each query through the proxy shows which query is wrong.

- A variable comes after every variable it uses.
- The child's matcher holds `$parent`; with several parent values it needs `=~`.
- `service_name` in PromQL and LogQL, `resource.service.name` in TraceQL.
- Test every panel with the values written in by hand through the proxy.

<!-- astrona:playground:destroy -->
