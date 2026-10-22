# Interpolation Formats And Variable Scopes

A service variable that allows several values is only useful if the query still works when the reader picks two services. The query text has to change shape: `service_name="checkout"` must become something that matches `checkout` or `payments`. Perses decides that shape with an **interpolation format**. This part shows the formats, and then the other question every shared variable raises: where it is defined, and which definition a dashboard uses.

## How a value becomes text

A query can name a variable in three ways: `$service`, `${service}`, and `${service:format}`. The first two use the default format; the third chooses one. The default depends on how many values are selected:

| Selected | Default format | `checkout` and `payments` become |
| --- | --- | --- |
| One value | `raw` | `checkout` |
| Several values | `prometheus` | `(checkout\|payments)` |

The `prometheus` format is a regular expression group, so it fits a regular expression matcher. With `service_name=~"$service"`, two selected values give `service_name=~"(checkout|payments)"`, and one value gives `service_name=~"checkout"`. Both are valid PromQL, and both are valid LogQL and TraceQL too, because `=~` works the same way in all three.

You can test the two-value shape yourself, through the proxy:

<!-- astrona:playground:renew -->

```sh
curl -s http://perses.localtest.me:8080/proxy/globaldatasources/prometheus/api/v1/query \
  --data-urlencode 'query=sum by (service_name) (rate(app_requests_total{service_name=~"(checkout|payments)"}[5m]))' \
  | jq -r '.data.result[].metric.service_name'
```

Both services come back. With `service_name="(checkout|payments)"`, using `=` instead of `=~`, nothing would: `=` compares text exactly, and no service is called `(checkout|payments)`.

## Other formats

Other backends and other places in a query need other shapes. These are the formats Perses v0.54.0 knows, shown for the values `checkout` and `payments`:

| Format | Result | Typical use |
| --- | --- | --- |
| `prometheus` | `(checkout\|payments)` | Regular expression matchers (default for several values) |
| `raw`, `csv` | `checkout,payments` | Comma lists (`raw` is the default for one value) |
| `pipe` | `checkout\|payments` | Alternatives without brackets |
| `regex` | `(checkout\|payments)`, with regular expression characters escaped | Values that contain `.` or `-` |
| `singlequote`, `doublequote` | `'checkout','payments'` / `"checkout","payments"` | Quoted lists |
| `sqlstring` | `'checkout','payments'`, with `'` doubled | SQL |
| `json` | `["checkout","payments"]` | JSON bodies |
| `glob` | `{checkout,payments}` | Glob patterns |
| `lucene` | `("checkout" OR "payments")` | Lucene and OpenSearch queries |
| `queryparam` | `service=checkout&service=payments` | URL query strings |
| `percentencode` | The comma list, URL-encoded | URL paths |
| `text` | `checkout + payments` | Display names |

The `All` entry follows the same rules: it selects every value, unless `customAllValue` is set, in which case that text is written instead. A `customAllValue` of `.*` with `=~` matches every service, even ones that appear after the list was loaded.

## Where a variable lives

Like datasources, variables have three scopes. A dashboard variable is an entry in `spec.variables`. A `Variable` belongs to a project, and a `GlobalVariable` to the whole server; the dashboards of a project show them next to their own variables. When the same name exists at several scopes, the smallest scope wins: dashboard, then project, then global.

Create a global environment list for every project. Save this as `globalvariable-region.yaml`:

```yaml
kind: GlobalVariable
metadata:
  name: region
spec:
  kind: ListVariable
  spec:
    display:
      name: Region
      hidden: false
    allowAllValue: false
    allowMultiple: false
    plugin:
      kind: StaticListVariable
      spec:
        values:
          - eu
          - us
```

Apply it:

```sh
percli apply -f globalvariable-region.yaml
```

Then check the result; `gv` is the short name for `globalvariable`:

```sh
percli get gv
```

A `GlobalVariable` and a project `Variable` have no `name` inside their `spec`; their name is `metadata.name`. Open any dashboard of `inventory`, and `Region` appears with the other variables. A project `Variable` named `region` in `inventory` would replace it for that project only, and a dashboard variable named `region` would replace both for that one dashboard.

This rule is useful and easy to forget. A project override that was right a year ago keeps hiding the global list long after the global list was corrected. When a dropdown shows values you did not expect, look for the same name at a smaller scope first.

You can now write several values into a query in the shape the backend needs, and you know which definition of a variable a dashboard uses. The summary closes the module.

## Common pitfalls

> [!WARNING]
> - **`=` with a multi-value variable.** Two values become `(a|b)`, which `=` compares as plain text. Use `=~`.
> - **`regex` where `prometheus` is meant.** Both give a group, but `regex` also escapes characters; a value with a `.` then matches only a literal dot.
> - **A stale project override.** A project `Variable` hides the `GlobalVariable` of the same name. Check `percli get var` in the project when values look wrong.
> - **A `name` inside the spec of a `GlobalVariable`.** It takes its name from `metadata.name`; only dashboard variables have `spec.name`.
