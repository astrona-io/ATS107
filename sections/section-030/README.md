# Section 030: Dashboard Variables

A dashboard with `service_name="checkout"` written into every query only works for one service. Copy it for `payments` and you have two dashboards to keep in step. **Variables** solve that: a dropdown at the top of the dashboard holds the value, and every query uses it. This section teaches the kinds of variables Perses has, where their values come from, how a value is written into a query, and where a variable can be defined.

**Topic covered:** Variables and scopes

## What you will learn

- `TextVariable` and `ListVariable`, and the fields of a list variable: `allowMultiple`, `allowAllValue`, `customAllValue`, `defaultValue`, `sort` and `capturingRegexp`.
- List values from a `StaticListVariable`, `PrometheusLabelValuesVariable`, `PrometheusPromQLVariable` and `LokiLabelValuesVariable`.
- A `DatasourceVariable` that lets the reader pick the datasource, and a query that uses it.
- Interpolation formats: how one or several values are written into PromQL, LogQL or TraceQL.
- Variables at dashboard, project and global scope, and which one a dashboard uses.

## The learning path

The section has two modules. Each has a landing page, several short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Make Dashboards Interactive With Variables

The playground holds Perses with a default global datasource for each backend and a second Prometheus datasource, `prometheus-replica`.

1. List And Text Variables
2. Variables Backed By Queries And Datasources, followed by the lab **Add A Datasource Selector And A Service Variable**
3. Interpolation Formats And Variable Scopes
4. Summary

### 2. Use Built-In Variables And Choose Groupings

The playground holds Perses with a default global datasource for each backend, a second Prometheus datasource, `prometheus-replica`, and telemetry for `checkout` and `payments` in `production` and `staging`.

1. Built-In Variables
2. The Rate Interval
3. Variables That Choose A Grouping, followed by the lab **Make A Rate Dashboard Adapt To Its Window**
4. Query Results As Variable Values
5. Summary

## Section capstone: Fix Variables That Show The Wrong Values

The capstone is one graded scenario that combines the modules. The dashboard `overview` of the project `inventory` offers environments that do not exist, an empty service list, and a panel that breaks as soon as the reader picks two services. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-107-capstone-030
```
