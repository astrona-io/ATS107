# Markdown Panels And Instant Queries

A dashboard with only numbers leaves the reader guessing what each number means and what to do about it. Two more panels fill that gap: a `Markdown` panel for text, and a `Table` for the exact values behind the charts. The table needs one new idea, the instant query, so this part explains both.

## A Markdown panel

A `Markdown` panel has no query. Its only field is `text`, which holds Markdown. Use it to state what the dashboard shows, what the thresholds mean and who owns the service. Add this panel to the `panels` map of the dashboard `numbers`:

<!-- astrona:playground:renew -->

```yaml
    notes:
      kind: Panel
      spec:
        display:
          name: How to read this dashboard
        plugin:
          kind: Markdown
          spec:
            text: |
              ## Requests
              The stat shows the request rate of all services.
              The gauge turns orange above 60 percent and red above 80 percent
              of the traffic going to `checkout`.
```

Give it a grid item such as `x: 16`, `y: 6`, `width: 8`, `height: 8` with `$ref: "#/spec/panels/notes"`, apply the file again, and reload the dashboard. The panel shows a heading and two lines of text. Text in a Markdown panel is static: it does not use variables and it does not change when the data changes.

## Range queries and instant queries

A `TimeSeriesChart` asks Prometheus for a **range query**: the value of an expression at many points between the start and the end of the time range. A table, a stat or a bar chart often needs only the current value of each series. For that, the `PrometheusTimeSeriesQuery` has the field `instant`. With `instant: true`, Perses asks for one value for each series, at the end of the time range, using the instant query endpoint of Prometheus.

You can see the difference with `curl`. The range endpoint returns a list of points for each series:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query_range \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total[5m]))' \
  --data-urlencode "start=$(date -d '-10 minutes' +%s 2>/dev/null || date -v-10M +%s)" \
  --data-urlencode "end=$(date +%s)" --data-urlencode 'step=60' \
  | jq '.data.result[0].values | length'
```

The number is the count of points in the first series. The instant endpoint returns exactly one point for each series:

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total[5m]))' \
  | jq '.data.result[0].value | length'
```

The answer is `2`: the time stamp and the value.

## A table of current values

A `Table` draws the result of a query as rows. With an instant query, it draws one row for each series, with the labels and the value. Add this panel and give it a grid item in the same way:

```yaml
    current:
      kind: Panel
      spec:
        display:
          name: Current request rates
        plugin:
          kind: Table
          spec:
            density: compact
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (service_name, deployment_environment) (rate(app_requests_total[5m]))
                  instant: true
```

After you apply the file, the table shows one row for each pair of service and environment. The setting `density` takes `compact`, `standard` or `comfortable` and changes the height of the rows. The `Table` plugin also has `columnSettings`, where each entry names a column with `name` and can set a `header`, a `format`, an `align` and `hide`; use them to rename or hide columns.

You now have the panels for single numbers, comparisons, text and exact values. The next step is making the layout of those panels deliberate, and that is a topic of its own.

## Common pitfalls

> [!WARNING]
> - **Putting a variable in a Markdown panel.** The text is static. Variables work in queries only.
> - **A table on a range query.** You get many rows or a hard-to-read result. Set `instant: true` when you want the current value.
> - **A `date` command that differs by system.** The example above tries the GNU form first and the macOS form second.
