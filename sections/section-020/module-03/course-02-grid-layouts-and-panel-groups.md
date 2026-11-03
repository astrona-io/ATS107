# Grid Layouts And Panel Groups

A panel is defined once under `spec.panels`, and placed one or more times under `spec.layouts`. The panel definition says what to show; the layout says where. This part explains how the grid works, how to split a dashboard into groups that a reader can collapse, and what happens when the two lists disagree.

## The 24-column grid

A layout of kind `Grid` has `items`. Each item has four numbers and a reference to a panel:

| Field | Meaning |
| --- | --- |
| `x` | The column where the panel starts, from 0 to 23 |
| `y` | The row where the panel starts, counted from the top |
| `width` | How many of the 24 columns the panel covers |
| `height` | How many rows the panel covers |
| `content.$ref` | The panel, written as `"#/spec/panels/<key>"` |

A width of 24 fills the screen, 12 is half, 8 is a third. Two panels at `x: 0` and `x: 12`, both with `width: 12`, sit side by side. A panel at `y: 8` sits under a panel at `y: 0` with `height: 8`. Perses packs items upward when the space above is free, so a gap in `y` closes by itself in the interface.

One panel can be referenced by more than one item, but the interface usually keeps it to one.

## Panel groups

A dashboard may have several `Grid` layouts. Each one is a group. A group with `display.title` shows a header, and `display.collapse.open` decides whether it starts open or closed. A closed group does not show its panels until the reader opens it, which makes it a good place for detail panels.

Save this as `dashboard-traffic.yaml`, replacing the earlier file. It keeps the rate panel in a group without a title, and adds a second panel in a closed group named `Details`:

<!-- astrona:playground:renew -->

```yaml
kind: Dashboard
metadata:
  name: traffic
  project: inventory
spec:
  display:
    name: Traffic
  duration: 1h
  panels:
    rate:
      kind: Panel
      spec:
        display:
          name: Requests per second
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              position: right
              mode: table
              values:
                - last
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (service_name) (rate(app_requests_total[5m]))
                  seriesNameFormat: "{{service_name}}"
    by-env:
      kind: Panel
      spec:
        display:
          name: Requests per second by environment
        plugin:
          kind: TimeSeriesChart
          spec:
            legend:
              position: bottom
        queries:
          - kind: TimeSeriesQuery
            spec:
              plugin:
                kind: PrometheusTimeSeriesQuery
                spec:
                  query: sum by (deployment_environment) (rate(app_requests_total[5m]))
                  seriesNameFormat: "{{deployment_environment}}"
  layouts:
    - kind: Grid
      spec:
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/rate"
    - kind: Grid
      spec:
        display:
          title: Details
          collapse:
            open: false
        items:
          - x: 0
            y: 0
            width: 24
            height: 8
            content:
              $ref: "#/spec/panels/by-env"
```

Apply it with `percli apply -f dashboard-traffic.yaml` and reload the dashboard. The first panel is visible. Below it is a header `Details` with an arrow, and the second panel is hidden until you click the header.

## Panels and layouts are separate lists

Because panels and layouts are separate lists, they can drift apart. A panel that is in `spec.panels` but in no layout is valid and never shown. A layout item that points to a key that does not exist is an error, and `percli apply` refuses the file. Renaming a panel key means changing both places.

Check the dashboard for orphans with `jq`. This prints the keys of panels that no layout places:

```sh
percli get dashboard traffic -o json | jq -r '
  [.spec.layouts[].spec.items[].content["$ref"] | sub("^#/spec/panels/"; "")] as $placed
  | .spec.panels | keys[] | select(. as $k | $placed | index($k) | not)'
```

An empty answer means every panel is placed.

## Common pitfalls

> [!WARNING]
> - **Widths that add up to more than 24 in one row.** The second panel wraps below the first. Keep the widths of one row to 24 at most.
> - **A panel key renamed in one list only.** The layout then points to a key that does not exist and `percli apply` fails.
> - **Putting the most important panel in a closed group.** A collapsed group is hidden on first load. Keep the panels a reader needs first in an open group.
