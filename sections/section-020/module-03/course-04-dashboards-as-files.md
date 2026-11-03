# Dashboards As Files

A dashboard built by clicking exists only in the Perses database. A dashboard kept as a file can be reviewed, versioned, repeated in another project and rebuilt after a loss. This part shows the commands that move a dashboard between the server and a file, and the check you run before you apply it.

## The four commands

| Command | What it does |
| --- | --- |
| `percli get dashboard NAME -o yaml` | Prints the stored dashboard as YAML; `-o json` prints JSON |
| `percli apply -f FILE` | Creates the resource in the file, or replaces it when it exists |
| `percli lint -f FILE` | Checks the file against the schemas without sending it to the server |
| `percli delete dashboard NAME` | Removes the dashboard from the selected project |

The commands act on the project you selected with `percli project inventory`. The `get` and `delete` commands list resources by kind: `percli get dashboard` without a name lists the dashboards of the project.

## Export a dashboard

Export the dashboard you built in the earlier parts:

<!-- astrona:playground:renew -->

```sh
percli get dashboard traffic -o yaml > dashboard-traffic.yaml
```

The file has the same shape as the files you wrote by hand, with extra fields the server adds, such as `createdAt`, `updatedAt` and `version` under `metadata`. Perses ignores the timestamps when you apply the file again, so you may leave them in or delete them.

## Check a file before you apply it

Edit the file: change the `refreshInterval` to `1m`. Then check it:

```sh
percli lint -f dashboard-traffic.yaml
```

When the file is valid, the command prints nothing about errors and exits with status `0`. Break the file on purpose to see an error: change `kind: TimeSeriesChart` to `kind: TimeSeriesChartt`, then run the lint command again. The command reports that the plugin kind is unknown and exits with a non-zero status. Fix the spelling.

Checking a file does not need a cluster, so the same command can run in a pipeline for every change to a dashboard file.

## Apply, then delete

Apply the file and confirm the change reached the server:

```sh
percli apply -f dashboard-traffic.yaml
percli get dashboard traffic -o yaml | grep refreshInterval
```

To copy the dashboard to a new name, change `metadata.name` in the file to `traffic-copy` and apply it again. The server then has two dashboards. Delete the copy:

```sh
percli delete dashboard traffic-copy
```

## Why keep files

A file lets you answer "who changed the legend and why" in a review, repeat the same dashboard in a second project by changing `metadata.project`, and restore a dashboard after someone deletes it in the interface. It also keeps the whole dashboard in one place, so a change to a query and the panel that shows it travel together.

## Common pitfalls

> [!WARNING]
> - **Applying a file from the wrong project.** `percli apply` uses the project named in `metadata.project` of the file; check it before you apply a copy.
> - **Trusting a dashboard in the interface over the file.** An edit in the interface is not written back to the file. After any such edit, export again.
> - **Skipping `percli lint`.** A typo in a plugin kind is found at apply time, one file at a time. Lint finds it before.

## Your mission: Tune A Traffic Dashboard

You can now set the options of a time series chart, group panels on a grid, set the window and refresh of a dashboard and keep it as a file. The graded lab gives you a plain `traffic` dashboard in the project `inventory`. You tune its panel, add a collapsed group, and set the time defaults, without losing the original panel.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-107-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-107-lab-020-03
astrona start ats-107-playground-020-03
```
