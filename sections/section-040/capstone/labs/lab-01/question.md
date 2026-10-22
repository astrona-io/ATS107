# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Unified incident dashboard

## Scenario

During last night's incident, the on-call engineer opened the dashboard `incident` of the project `inventory`, picked `staging`, and was offered `payments`, which does not run in `staging`. After picking a real pair, `production` and `checkout`, only the request rate panel showed data. The logs and traces panels stayed empty, although Loki and Tempo hold the data.

## Your task

Repair the dashboard `incident` so that:

1. The service list only offers services that run in the selected environment.
2. The logs panel shows the logs of the selected environment and service.
3. The traces panel shows the traces of the selected environment and service.

## Constraints

- Repair the dashboard; keep the panels `request-rate`, `logs` and `traces` and the variables `env` and `service`.
- Do not create or change datasources.

## Done when

- `env` comes before `service`, and the matcher of `service` uses `$env`.
- For `staging`, the service list holds only `checkout`; for `production`, it holds `checkout` and `payments`.
- Each of the three queries uses `$env` and `$service`, and returns data for `production`/`payments` and for `staging`/`checkout`.
