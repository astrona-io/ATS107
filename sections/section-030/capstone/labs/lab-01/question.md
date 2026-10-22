# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Variables and scopes

## Scenario

The dashboard `overview` of the project `inventory` is supposed to show the request rate of any services in any environment. Readers report three problems. The environment dropdown offers `prod` and `stage`, which match no data. The service dropdown is empty. And when someone types two services into it anyway, the panel goes blank.

The platform team keeps a `GlobalVariable` named `env` with the right environments for every project, and they do not want it changed.

## Your task

Make the dashboard `overview` work again:

1. The environment variable `env` that the dashboards of `inventory` get must offer `production` and `staging`.
2. The service variable `service` must list the services of the selected environment.
3. The panel `requests` must show data when the reader selects one or several services.

## Constraints

- Do not change the `GlobalVariable` named `env`.
- Keep the dashboard variable `service` and the panel `requests`; repair them.

## Done when

- The `env` values that `inventory` gets are exactly `production` and `staging`.
- `service` reads the label `service_name`, and for `production` lists `checkout` and `payments`.
- The panel query returns data for `production` with both services selected.
