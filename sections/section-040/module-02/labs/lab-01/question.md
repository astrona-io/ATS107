# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Variable cascades

## Scenario

The dashboard `explorer` of the project `inventory` has a log panel `logs` and a trace panel `traces`, and both are fixed on the service `checkout`. During an incident the on-call engineers need to look at both environments and both services together, search the log lines for a word, and show only the slow traces. `checkout` runs in `production` and `staging`, `payments` only in `production`.

## Your task

Change the dashboard `explorer` so that:

1. A variable `env` lists the values of the Prometheus label `deployment_environment` on `app_requests_total`. It allows several values and an `All` entry that writes `.*`.
2. A variable `service` lists the values of the label `service_name` on `app_requests_total`, only for the environments selected in `env`. It allows several values and an `All` entry that writes `.*`.
3. A text variable `search` starts with the text `order`.
4. A single-value list variable `slower` holds the durations `0ms`, `10ms`, `100ms` and `1s`, and starts at `0ms`.
5. The log panel shows the lines of the selected environments and services that contain the search text.
6. The trace panel shows the traces of the selected environments and services that have a span slower than the selected duration.

## Constraints

- Keep the panels `logs` and `traces`; change their queries, do not replace the panels.
- Use the default global datasources; do not create new datasources.

## Done when

- `env` comes before `service`, and the matcher of `service` uses `$env` with `=~`.
- With `staging` selected, the service list holds only `checkout`; with both environments, it holds `checkout` and `payments`.
- The log query uses `$env`, `$service` and `$search`, and the trace query uses `$env`, `$service` and `$slower`.
- Every query returns data with `All` selected, with both environments and services selected, and with `staging` and `checkout` selected.
