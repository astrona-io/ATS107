# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Panels per signal

## Scenario

The team of `checkout` copied the dashboard `signals` from another team and changed it for their service. Now it shows almost nothing. The request rate panel is empty, the logs panel reports an error, and the traces panel is nowhere to be seen. The profile panel still works. The backends are healthy, and the default global datasources `prometheus`, `loki`, `tempo` and `pyroscope` are correct.

## Your task

Repair the dashboard `signals` in the project `inventory` so that every panel shows the data of `checkout`:

1. The request rate panel shows the request rate of `checkout`.
2. The logs panel shows the logs of `checkout`.
3. The traces panel appears on the dashboard and lists the traces of `checkout`.

## Constraints

- Repair the panels; do not delete any of the four panels or rename their keys.
- Do not create or change datasources; the global defaults are correct.

## Done when

- The panels `requests`, `logs`, `traces` and `profile` still exist.
- Every panel is placed in the layout.
- Every panel's query returns data through the Perses proxy.
