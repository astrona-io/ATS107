# Tune And Scope Datasources

A datasource is more than an address. Each plugin has its own settings, each backend answers on its own paths, and a datasource can live inside a single dashboard. When a panel stays empty, you need to know which of these three things is wrong and how to prove it with a command.

This module goes one level below the basics of datasources. The sentence to keep in mind is: **a datasource is a plugin kind plus an HTTP settings block, stored at one scope, and every setting can be read back and tested through the Perses proxy.**

The module has four parts. **Settings Of A Prometheus Datasource** reads the fields of a `PrometheusDatasource` and of its `proxy` block. **Loki, Tempo And Pyroscope Datasources** compares the three other backends and the paths each one answers on. **Datasources Inside A Dashboard** stores a datasource in the dashboard itself and ends with a graded lab. **Find Out Why A Datasource Fails** gives a fixed order of checks for a panel that shows nothing.

## Learning objectives

After this module you can:

- Name the fields of a `PrometheusDatasource` and say what `scrapeInterval`, `queryParams` and `exemplars` change.
- Say when to use `directUrl` and when to use `proxy`, and why a datasource cannot have both.
- Create a project `Datasource` for Loki, Tempo and Pyroscope and call each one through the proxy.
- Define a datasource inside a dashboard and call it through the dashboard proxy path.
- Work through a failing datasource in a fixed order: scope, definition, path, status code.

## Before you start

You need to know the three datasource scopes, the smallest-scope-wins rule, `percli apply` and `curl` with `jq`.

Your playground is a single-node `kind` cluster with **Perses v0.54.0** in the namespace `perses`, with authentication off. The namespace `observability` runs Prometheus, Loki, Tempo and Pyroscope. Perses already holds the project `inventory` and the global datasources `prometheus`, `loki`, `tempo` and `pyroscope`. The global `loki` datasource points at a gateway that asks for a password and sends none, so it answers `401`; this module uses a project datasource that talks to Loki directly.

Start the port-forward in a second terminal (`kubectl -n perses port-forward svc/perses 8080:8080`), then run `percli login http://perses.localtest.me:8080` and `percli project inventory` before you read on.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
