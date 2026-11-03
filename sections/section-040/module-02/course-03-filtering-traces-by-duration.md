# Filtering Traces By Duration

A trace table with every trace of a service is as long as a log table with every line. During an incident the useful question is "show me the slow ones". TraceQL filters on the duration of a trace or span, and a variable lets the reader choose the limit. This part adds that choice and ends with the graded lab.

## Duration in TraceQL

TraceQL compares durations with a number and a unit: `ns`, `us`, `ms`, `s`, `m` and `h`. A span filter inside braces reads:

```text
{ resource.service.name = "checkout" && duration > 100ms }
```

The intrinsic field `duration` is the duration of the span. Several conditions inside one pair of braces are joined with `&&` and must all be true for the same span. The two attributes you used in earlier queries are resource attributes, so they carry the prefix `resource.`; `duration` is built in and has no prefix.

A trace appears in the answer when at least one of its spans matches. With the filter above, a trace with one span slower than 100 milliseconds is returned in full.

## A list of limits

Reuse the labels you know and add a list of limits. Add this variable to `dashboard-explorer.yaml`, after `search`:

<!-- astrona:playground:renew -->

```yaml
    - kind: ListVariable
      spec:
        name: slower
        display:
          name: Slower than
          hidden: false
        allowAllValue: false
        allowMultiple: false
        defaultValue: 0ms
        plugin:
          kind: StaticListVariable
          spec:
            values:
              - value: 0ms
                label: Any duration
              - value: 10ms
                label: 10 milliseconds
              - value: 100ms
                label: 100 milliseconds
              - value: 1s
                label: 1 second
```

Then add a panel with a trace table to the same file. Add this panel under `spec.panels`:

```yaml
    traces:
      kind: Panel
      spec:
        display:
          name: Traces
        plugin:
          kind: TraceTable
          spec: {}
        queries:
          - kind: TraceQuery
            spec:
              plugin:
                kind: TempoTraceQuery
                spec:
                  query: '{resource.deployment.environment =~ "$env" && resource.service.name =~ "$service" && duration > $slower}'
                  limit: 20
```

Place it under the logs panel by adding this item to the items of the grid layout:

```yaml
          - x: 0
            y: 10
            width: 24
            height: 10
            content:
              $ref: "#/spec/panels/traces"
```

Apply the file with `percli apply -f dashboard-explorer.yaml` and choose `1 second` in the new dropdown. The table gets shorter, and it can become empty if no span is that slow. Choose `Any duration` and it fills again, because every span is longer than zero.

## Why the value carries its unit

The variable holds `100ms`, not `100`, so the query reads `duration > 100ms`. A bare number would be a different thing in TraceQL, as a duration needs a unit. Keep the unit in the value and the words in the label.

## Test the query by hand

The query text with the variables written in is:

```sh
curl -s -G http://perses.localtest.me:8080/proxy/globaldatasources/tempo/api/search \
  --data-urlencode 'q={resource.deployment.environment =~ ".*" && resource.service.name =~ ".*" && duration > 0ms}' \
  --data-urlencode 'limit=20' | jq '.traces | length'
```

The count is above zero. This is the form your query takes when both multi-value variables are on `All` and the duration is `Any duration`.

## Your mission: Filter Logs And Traces By Several Selections

You can now build multi-value variables that depend on each other, a search field for logs and a duration choice for traces. The graded lab gives you a dashboard `explorer` in the project `inventory` whose log and trace panels are fixed on `checkout`. You add the variables and make both panels follow them.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-040-02
astrona start ats-107-playground-040-02
```

## Common pitfalls

> [!WARNING]
> - **A duration without a unit.** `duration > 100` is not a valid comparison. Write `100ms`.
> - **Resource attributes without the `resource.` prefix.** `service.name` alone looks for a span attribute and finds nothing.
> - **Conditions in separate braces.** `{a} && {b}` combines spans of the same trace; `{a && b}` needs both on one span.
