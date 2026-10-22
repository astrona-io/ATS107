# Summary

Every Perses query reaches its backend through a datasource. A datasource names a backend plugin, such as `PrometheusDatasource` or `LokiDatasource`, and says how the Perses server reaches it. This module showed where datasources live, how the Perses server forwards a query, and how a datasource gets the credentials its backend asks for.

## What you learned

A datasource can live at three scopes. A `GlobalDatasource` serves every project, a project `Datasource` serves the dashboards of one project, and a datasource inside a dashboard serves only that dashboard. A query names a datasource by kind and, optionally, by name. Without a name it uses the default datasource of its kind, the one with `default: true`. When several datasources share a name, the smallest scope wins, so one project can override a shared datasource without changing it for anyone else.

With a `proxy` block, the browser never talks to the backend. It sends the query to a path on the Perses server, and the Perses server forwards it to the `url` of the datasource. The path is `/proxy/globaldatasources/<name>/...` for a global datasource and `/proxy/projects/<project>/datasources/<name>/...` for a project one, followed by the backend's own path. You can call that path yourself with `curl` to test a datasource without a dashboard. An `allowedEndpoints` list limits the proxy to pairs of a method and a path pattern; the Perses server refuses anything else before it reaches the backend. A status code from `curl` tells you whether Perses or the backend refused a request.

Credentials belong in a Secret: a `GlobalSecret` for a global datasource, a project `Secret` for a project or dashboard datasource. The Secret holds `basicAuth`, `authorization` or `oauth`, plus an optional `tlsConfig`, and the datasource references it by name in `proxy.spec.secret`. The Perses server then adds the credentials to every forwarded request. Credentials in a proxy header work too, but they sit in plain sight next to every other setting.

- The smallest scope wins: dashboard, then project, then global.
- A query without a datasource name uses the default of its kind.
- `allowedEndpoints` is a list of method and path pattern pairs; a missing list forwards everything.
- A project datasource uses a project `Secret`; a global datasource uses a `GlobalSecret`.

<!-- astrona:playground:destroy -->
