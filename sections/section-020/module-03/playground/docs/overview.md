# Overview: Tune Time Series, Layouts And Dashboard Files (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs the backends and Perses, creates the starting resources, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Perses v0.54.0** in the namespace `perses`, authentication off, and `percli` 0.54.0 on your PATH.
- The namespace **`observability`** with Prometheus, Loki, Tempo and Pyroscope, and telemetry for `checkout` and `payments` in `production` and `staging`.
- The project **`inventory`** and a default global datasource for each backend: `prometheus`, `loki`, `tempo` and `pyroscope`.

Start the port-forward in a second terminal and leave it running, then log in:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

## Helpers

Paste these once in each new terminal. `show_layouts` prints, for each layout of a dashboard, its title and the panels it places. `unplaced` prints the keys of panels that no layout places.

```sh
show_layouts() {
  percli get dashboard "$1" -o json | jq -r '.spec.layouts[] | "\(.spec.display.title // "(no title)"): \([.spec.items[].content["$ref"]] | join(", "))"'
}
unplaced() {
  percli get dashboard "$1" -o json | jq -r '
    [.spec.layouts[].spec.items[].content["$ref"] | sub("^#/spec/panels/"; "")] as $placed
    | .spec.panels | keys[] | select(. as $k | $placed | index($k) | not)'
}
```

Use them like this: `show_layouts traffic`, `unplaced traffic`.

## Practice tasks

- Switch `legend.mode` between `list` and `table`, and add the values `mean` and `min`.
- Set `visual.stack: all` on a chart with two series, and compare the top line with `sum(rate(app_requests_total[5m]))`.
- Remove `yAxis.min` and watch how the same chart looks with a small change.
- Make a panel `width: 16` and put another beside it with `x: 16` and `width: 8`.
- Open the dashboard with `?start=15m&refresh=10s` at the end of the address and compare it with the saved defaults.
- Lint a file with a misspelled plugin kind, then fix it.
