# Section 010: Datasources And Their Scopes

A Perses dashboard never talks to Prometheus, Loki or Tempo by itself. Every query goes through a **datasource**, the Perses resource that says which backend to use and how to reach it. When a panel stays empty, the datasource is the first place to look: it can point at the wrong address, forward the wrong paths, miss its credentials, or be shadowed by another datasource with the same name.

This section teaches the three things a datasource decides. Its **scope** decides which dashboards can use it and which one wins when two share a name. Its **proxy** decides which backend paths the Perses server forwards. Its **Secret** decides which credentials the Perses server sends to the backend.

**Topic covered:** Datasources, the proxy and Secrets

## What you will learn

- The difference between a `GlobalDatasource`, a project `Datasource` and a datasource inside a dashboard, and why the smallest scope wins.
- What the `default` flag does when a query names no datasource.
- How the Perses proxy forwards a query, and how to call it yourself with `curl`.
- How `allowedEndpoints` limits what the proxy forwards, and how to prove it.
- How to keep a backend's credentials in a `Secret` or `GlobalSecret` and reference it from a datasource.

## The learning path

The section has one module. It has a landing page, three short parts, a graded lab right after the third part, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Connect Perses To Your Data Backends

The playground holds Perses, the project `inventory` and a global datasource for each backend. The global Loki datasource points at a gateway that asks for a password, and it has none.

1. Datasources, Scopes And Overrides
2. The Perses Proxy And Allowed Endpoints
3. Secrets For Datasource Credentials, followed by the lab **Give A Project Its Own Loki Datasource**
4. Summary

## Section capstone: Repair The Datasources Of A Project

The capstone is one graded scenario that combines everything in the section. Three datasources the project `inventory` relies on are broken in three different ways, and every dashboard of the project shows empty panels. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-107-capstone-010
```
