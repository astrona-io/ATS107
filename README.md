# ATS107 — Multi-Pillar Datasources & Variable Scopes (Perses)

Course material for the **Multi-Pillar Datasources & Variable Scopes** domain
of the Astrona Perses training path ([ATP021](https://github.com/astrona-io/ATP021)),
which is **20% of the path**. Written for **Perses v0.54.0**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Perses v0.54.0 documentation, source and plugin schemas. None has
> been started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md` for the open risks.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Datasources And Their Scopes | 1 | 1 + capstone | Datasources, the proxy, Secrets |
| [020](sections/section-020) | Metrics, Logs, Traces And Profiles | 1 | 1 + capstone | Panels per signal |
| [030](sections/section-030) | Dashboard Variables | 1 | 1 + capstone | Variables and scopes |
| [040](sections/section-040) | Cascading Variables Across Signals | 1 | 1 + capstone | Unified incident dashboard |

The order follows the path of one query. Section 010 is where the query goes:
a datasource and the Perses proxy. Section 020 is what draws its answer: one
panel per signal. Section 030 makes the query take values from the reader,
and section 040 makes one selection drive metrics, logs and traces at once.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Connect Perses To Your Data Backends](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Show Metrics, Logs, Traces And Profiles](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Make Dashboards Interactive With Variables](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Build A Unified Incident Dashboard](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair The Datasources Of A Project | a wrong backend port, a stale Secret password, an endpoint list that blocks trace search |
| [020](sections/section-020/capstone/labs/lab-01) | Repair A Dashboard That Shows Nothing | a wrong label in PromQL, a datasource that does not exist, a panel missing from the layout |
| [030](sections/section-030/capstone/labs/lab-01) | Fix Variables That Show The Wrong Values | a stale project override of a global variable, a wrong label name, `=` where several values need `=~` |
| [040](sections/section-040/capstone/labs/lab-01) | Repair An Incident Dashboard That Hides Data | variables in the wrong order, a service list not filtered by environment, wrong labels in LogQL and TraceQL |

---

## The lab environment

Every playground and lab is a **kind** cluster with Perses v0.54.0 (chart
`perses` 0.23.3) in the namespace `perses`, and Prometheus 3.15.1, Loki 3.7.9
(with an nginx gateway that asks for basic authentication), Tempo 2.10.10 and
Pyroscope 2.4.1 in the namespace `observability`. Three `telemetrygen` pods
send metrics, logs and traces for `checkout` and `payments` in `production`
and `staging`, so all signals share the labels `deployment_environment` and
`service_name`.

Perses answers at `http://perses.localtest.me:8080` everywhere: on the
reader's machine through `kubectl -n perses port-forward svc/perses 8080:8080`,
and inside the cluster through a CoreDNS rewrite added by the bootstrap.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** of the Perses resources and runs every
panel's query through the Perses proxy. Several graders reject the
plausible-but-wrong fix (credentials in a proxy header, removing
`allowedEndpoints`, changing a global resource other projects rely on,
deleting a panel instead of repairing it).
