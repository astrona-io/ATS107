# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS107 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Multi-Pillar Datasources & Variable Scopes**
  domain of the **Perses** training path (`ATP021`). It is 20% of the path.
  There is no official Perses certification exam; the path's domains and
  weights are Astrona's own, set in `ATP021/path.yaml`.
- **What the domain really tests:** connecting Perses to metrics, logs, traces
  and profiles, and building dashboards whose variables drive every query.
  The student must *do* things: create a datasource at the right scope, store
  its credentials in a Secret, restrict the proxy, write panels for each
  signal, and make variables cascade from environment to service across
  PromQL, LogQL and TraceQL. Every explanation should lead to a command they
  can run, and every fix should be proved with a query through the Perses
  proxy that returns data.
- **The four topics:** datasources and their scopes, the four signals and
  their panels, dashboard variables, and variables that cascade across
  signals.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Datasources And Their Scopes | Datasources, the proxy, Secrets |
  | 020 | Metrics, Logs, Traces And Profiles | Panels per signal |
  | 030 | Dashboard Variables | Variables and scopes |
  | 040 | Cascading Variables Across Signals | Unified incident dashboard |

- **The versions:** **Perses v0.54.0** (chart `perses` 0.23.3, Helm 3.22.1,
  `percli` v0.54.0) on a single-node `kind` cluster. The plugins are the ones
  bundled in the v0.54.0 release archive: Prometheus 0.58.0, Loki 0.6.0,
  Tempo 0.59.0, Pyroscope 0.6.0, TimeSeriesChart 0.13.0, LogsTable 0.3.0,
  TraceTable 0.11.0, TracingGanttChart 0.13.0, ScatterChart 0.11.0,
  FlameChart 0.6.0, StaticListVariable 0.9.0, DatasourceVariable 0.6.0,
  VictoriaLogs 0.4.0. Backends: Prometheus **v3.15.1**, Loki **3.7.9**,
  Tempo **2.10.10**, Pyroscope **2.4.1**, telemetry from `telemetrygen`
  **v0.163.0**. Tempo stays on the 2.10 line on purpose: Tempo 3.0 removed the
  ingester write path and changed its single-binary configuration.
- **The main sources:** the Perses documentation,
  <https://perses.dev/perses/docs/overview/>, the `perses/perses` source at
  `v0.54.0` (`docs/`, `dev/data/`), and the CUE schemas inside each plugin
  archive of the v0.54.0 release (`schemas/` in every
  `plugins-archive/*.tar.gz`). Plugin kinds and fields in this course were
  read from those schemas. Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Perses v0.54.0
documentation, source and plugin schemas **without a live run**. No
playground or lab has been started, and no `astrona test` has passed yet.
Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The open risks, most likely first:

1. **Telemetry labels.** The course assumes `telemetrygen` resource attributes
   arrive as `service_name` and `deployment_environment` labels in Prometheus
   (through `otlp.promote_resource_attributes`) and in Loki (default OTLP
   index labels), and as `resource.service.name` /
   `resource.deployment.environment` in TraceQL. It also assumes the `Sum`
   metric `app_requests` becomes `app_requests_total` in Prometheus. Check
   with one query per backend first; every grader depends on this.
2. **Pyroscope self-profiling.** The profile panel and its grader assume
   Pyroscope 2.4.1 profiles itself (service `pyroscope`) with no extra
   configuration, and that `POST /querier.v1.QuerierService/ProfileTypes`
   through the proxy answers with at least one profile type.
3. **Proxy refusals.** Graders treat any status other than `200` from a path
   that `allowedEndpoints` does not list as "refused". The exact code is not
   documented.
4. **API create versus update.** Scripts `POST` a resource and fall back to
   `PUT` when the `POST` fails because the resource exists.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Signal (pillar) | One kind of telemetry: metrics, logs, traces or profiles |
| GlobalDatasource / Datasource / dashboard datasource | A datasource every project can use / one project can use / one dashboard can use; the smallest scope wins when names are equal |
| Default datasource | The datasource of a plugin kind (for example `PrometheusDatasource`) that a query uses when it names no datasource |
| `HTTPProxy` | The proxy configuration of a datasource: Perses forwards the browser's queries to `spec.url` |
| `allowedEndpoints` | The list of method and path pattern pairs the proxy forwards; anything else is refused |
| `directUrl` | A datasource the browser calls directly, without the Perses proxy |
| Secret / GlobalSecret | Credentials a project datasource / a global datasource sends to its backend (`basicAuth`, `authorization`, `oauth`, `tlsConfig`) |
| Panel plugin / query plugin | What draws the data (`TimeSeriesChart`, `LogsTable`, `TraceTable`, `FlameChart`) / what fetches it (`PrometheusTimeSeriesQuery`, `LokiLogQuery`, `TempoTraceQuery`, `PyroscopeProfileQuery`) |
| Query kind | The family a query plugin belongs to: `TimeSeriesQuery`, `LogQuery`, `TraceQuery`, `ProfileQuery` |
| `ListVariable` / `TextVariable` | A variable whose values come from a plugin / a free text value |
| Variable plugin | The source of a list variable's values: `StaticListVariable`, `PrometheusLabelValuesVariable`, `PrometheusPromQLVariable`, `LokiLabelValuesVariable`, `DatasourceVariable` |
| Interpolation format | How a variable's value is written into a query: `${service:regex}`, `${service:csv}`; the default is `prometheus` (`(a\|b)`) for several values and `raw` for one |
| Cascading variable | A variable whose query uses another variable, so its values change when the first one changes |
| OTLP | The OpenTelemetry Protocol; `telemetrygen` sends metrics, logs and traces with it |

### The example workloads

All backends live in the namespace `observability`; Perses lives in `perses`.

| Name | Image | What it is |
| --- | --- | --- |
| Perses | `persesdev/perses:v0.54.0` (chart 0.23.3) | Service `perses`, port `8080`, file database, authentication off |
| `prometheus` | `prom/prometheus:v3.15.1` | Port `9090`; OTLP receiver on (`--web.enable-otlp-receiver`), promotes `service.name` and `deployment.environment` to labels |
| `loki` | `grafana/loki:3.7.9` | Single binary, filesystem storage, port `3100`, OTLP logs at `/otlp/v1/logs` |
| `loki-gateway` | `nginx:1.27-alpine` | Basic authentication in front of Loki, port `80`; lab-only user `perses`, password `loki-gateway-password` |
| `tempo` | `grafana/tempo:2.10.10` | Single binary, local storage, HTTP port `3200`, OTLP gRPC `4317` |
| `pyroscope` | `grafana/pyroscope:2.4.1` | Single binary, port `4040`; profiles itself |
| `telemetry-<env>-<service>` | `ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.163.0` | One pod per combination: `production`/`checkout`, `production`/`payments`, `staging`/`checkout`. Three containers each send traces, logs and the counter `app_requests` |
| `tester` | `nicolaka/netshoot:v0.13` | `curl` and `jq`; graders call the Perses API and proxy from here |

Perses resources every environment starts with (section 010 changes the
Loki one): project `inventory`, and the default GlobalDatasources
`prometheus`, `loki`, `tempo` and `pyroscope`. The shared labels are
`deployment_environment` (`production`, `staging`) and `service_name`
(`checkout`, `payments`).

### Environment facts the text must respect

- **One address everywhere: `http://perses.localtest.me:8080`**, as in
  ATS106: a CoreDNS `rewrite stop` block (with the answer name rewritten back)
  inside the cluster, `kubectl -n perses port-forward svc/perses 8080:8080` on
  the reader's machine. Copy the block from an existing `prepare.sh`; never
  the one-line `rewrite name` form.
- **Datasource URLs are in-cluster names** (`http://prometheus.observability:9090`).
  The Perses server proxies every query, so the browser never needs them.
- **Proxy paths:** `/proxy/globaldatasources/<name>/<backend path>`,
  `/proxy/projects/<project>/datasources/<name>/<backend path>` and
  `/proxy/projects/<project>/dashboards/<dashboard>/datasources/<name>/<backend path>`
  (from `internal/api/impl/proxy/proxy.go` at `v0.54.0`).
- **Perses validates plugin specs when a resource is applied.** A wrong
  field fails at `percli apply`; a wrong label or datasource name does not.
  Labs therefore seed faults that pass validation and fail at query time.
- **Data needs a minute.** Bootstrap waits until `app_requests_total` exists
  in Prometheus; logs and traces arrive at the same time.
- **Many environments start broken on purpose.** The fault is the material.
  Never "fix" it in the bootstrap.

### Where things are in this repo

Same layout as ATS106: `astrona.yaml`, `README.md`, `sections/intro/`,
`sections/section-0N0/` with module pages, `playground/`, labs and a capstone.
Every environment has `manifests/perses-values.yaml`,
`manifests/lab-start.yaml` (the observability stack), and
`manifests/perses/*.json` (Perses resources applied in name order by the
bootstrap). Labs add `manifests/seed/*.json` for the starting state.

The plumbing of all twelve environments (manifests, `config.yaml`, the
bootstrap, testing, solution and validation scripts, `prerequisites.md` and
the author `README.md`s) was generated from one script kept outside this
repository. To change a shared piece (the stack, a helper function), change
it in **every** environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS107`, domain `Multi-Pillar Datasources & Variable
Scopes`, weight `20`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order.

- `topic`: exactly one of `datasources`, `proxy`, `secrets`, `panels`,
  `variables`, `cascading`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `global-datasource`,
  `project-datasource`, `datasource-override`, `default-datasource`,
  `http-proxy`, `allowed-endpoints`, `secret`, `basic-auth`, `prometheus`,
  `loki`, `tempo`, `pyroscope`, `time-series-chart`, `logs-table`,
  `trace-table`, `flame-chart`, `layout`, `promql`, `logql`, `traceql`,
  `list-variable`, `static-list`, `label-values`, `datasource-variable`,
  `interpolation-format`, `global-variable`, `project-variable`,
  `cascading-variables`, `percli-apply`.
- `resources`: 1 to 4 pages on `perses.dev` (or the Loki, Tempo and Pyroscope
  query language pages on `grafana.com`). The only place outside links are
  allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-010/module-01/playground
astrona destroy ats-107-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-107-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-107-playground-<section>-<module>`, `ats-107-lab-<section>-<module>`,
`ats-107-capstone-<section>`. Graders check **behaviour**: they read the
resource from the Perses API, then run each panel's or variable's query
through the Perses proxy and require data. They reject the plausible but
wrong fix (credentials in proxy headers instead of a Secret, removing
`allowedEndpoints` altogether, changing the GlobalDatasource another project
relies on, hard-coding a value a variable should provide, deleting a panel).
A lab's `question.md` and `solution.md` must match what its `validation/`
scripts check.

Test clusters on the maintainer's machine: one at a time; each environment
runs Perses and five backends, about 3 GiB.

### Where to find trusted sources

- **Datasources:** <https://perses.dev/perses/docs/concepts/datasource/>,
  scopes: <https://perses.dev/perses/docs/concepts/datasource-and-variable-scopes/>,
  Secrets: <https://perses.dev/perses/docs/api/secret/>
- **Variables:** <https://perses.dev/perses/docs/concepts/variable/>
- **Plugins:** <https://perses.dev/plugins/docs/> and the schemas in the
  release archive
- **Backends:** Prometheus OTLP
  (<https://prometheus.io/docs/guides/opentelemetry/>), Loki OTLP
  (<https://grafana.com/docs/loki/latest/send-data/otel/>), TraceQL
  (<https://grafana.com/docs/tempo/latest/traceql/>)
