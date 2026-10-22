# Section 040: Cascading Variables Across Signals

During an incident, the first two questions are always the same: which environment, and which service. An incident dashboard should ask them once, at the top, and then show the metrics, the logs and the traces of exactly that service in exactly that environment. Two things make that work: a service list that depends on the selected environment, and the same selection written correctly into three query languages.

This section builds that dashboard.

**Topic covered:** Unified incident dashboard

## What you will learn

- How one variable depends on another through `$name` in its matchers, and why the order of the variable list matters.
- What Perses does when the reader changes a variable that others depend on.
- How the same environment and service labels are named in PromQL, LogQL and TraceQL.
- How to write one selection into all three languages so every panel follows it.
- How to test a cascade and a dashboard by writing the values in by hand.

## The learning path

The section has one module with a landing page, two parts, a graded lab right after the second part, and a summary. The landing page starts the module's playground.

### 1. Build A Unified Incident Dashboard

The playground holds Perses with a default global datasource for each backend, and telemetry for `checkout` in `production` and `staging` and for `payments` in `production` only. That uneven split is what makes a cascade visible.

1. Variables That Depend On Other Variables
2. One Value In PromQL, LogQL And TraceQL, followed by the lab **Build A Unified Incident Dashboard**
3. Summary

## Section capstone: Repair An Incident Dashboard That Hides Data

The capstone is one graded scenario that combines the module. The incident dashboard of the project `inventory` lists every service for every environment, and two of its three panels stay empty whatever the reader selects. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-107-capstone-040
```
