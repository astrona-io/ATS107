# Filter Logs And Traces With Several Selections

A single environment and a single service are the easy case. During an incident the reader wants more: both environments at once, every service, only the log lines that mention one word, only the traces slower than a given time. Each of those is a variable, and each has a way of going wrong that a single-value dashboard never shows.

Keep one sentence in mind: **every selection becomes text inside a query, so the text must be valid in that query language for every value the reader can pick, including none, one, many and All.** This module builds the multi-value version of the incident dashboard and then teaches how to find the variable that breaks it.

The module has four parts. **Cascades With Many Values** makes a service list depend on a multi-value environment and handles `All`. **Search Text In Logs** adds a text field for a line filter. **Filtering Traces By Duration** adds a duration choice to a TraceQL query, and ends with a graded lab. **Debugging A Variable Cascade** gives the steps to find which variable is wrong.

## Learning objectives

After this module you can:

- Make a variable depend on a multi-value variable, and set `All` so it matches every value.
- Add a text variable to a LogQL line filter and say what happens with special characters.
- Filter a TraceQL query by duration with a variable.
- Find the variable that breaks a dashboard by testing each query through the proxy.

## Before you start

You need dashboard variables, the formats of multi-value selections, variable cascades, and the labels of PromQL, LogQL and TraceQL.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** and the observability stack. Prometheus, Loki and Tempo hold telemetry for `checkout` and `payments`; `checkout` runs in `production` and `staging`, `payments` only in `production`. The log lines read `order handled by checkout` and `order handled by payments`. The project `inventory` and the global datasources `prometheus`, `loki`, `tempo` and `pyroscope` exist.

Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory` before you read on.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
