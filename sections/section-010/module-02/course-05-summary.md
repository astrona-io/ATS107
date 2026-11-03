# Summary

A datasource is a plugin kind and an HTTP settings block, stored at one scope. This module read those settings, compared the four backends, stored a datasource inside a dashboard, and set out an order of checks for a datasource that fails.

## What you learned

Every HTTP datasource has exactly one of `proxy` and `directUrl`. With `proxy`, the Perses server forwards each query, can add headers and credentials, and can restrict paths with `allowedEndpoints`. With `directUrl`, the browser calls the backend itself. A `PrometheusDatasource` adds `scrapeInterval`, which sets the smallest step of a range query, `queryParams`, which are added to every request, and `exemplars`. A `PyroscopeDatasource` adds `minStep`. Loki and Tempo datasources have no extra fields.

Each backend answers on its own paths. Loki uses `/loki/api/v1`, Tempo uses `/api/search` for trace search, and Pyroscope uses `querier.v1.QuerierService`. The proxy path is the datasource name followed by the backend path, so an `allowedEndpoints` list is only as correct as your knowledge of those paths.

A dashboard can hold its own datasources in `spec.datasources`. They win over project and global datasources of the same name, they do not appear in the project datasource list, and they are called through `/proxy/projects/<project>/dashboards/<dashboard>/datasources/<name>/`. A dashboard datasource takes credentials from a project Secret.

When a panel is empty, check the scope, then the definition, then the path, then the status code. The status code shows whether the Perses server or the backend refused the request, and a `200` with no data points at the query.

- Exactly one of `proxy` and `directUrl`.
- Smallest scope wins: dashboard, project, global.
- Credentials and tokens never go in `headers`.
- `percli get dts` lists project datasources only.

<!-- astrona:playground:destroy -->
