# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster.
- **`percli`:** the Perses command-line tool. Each playground and lab also puts `percli` 0.54.0 in `/usr/local/bin` or `~/.local/bin`, so its version always matches the Perses server.
- **`helm`:** installs Perses. Each playground and lab also puts Helm 3.22.1 in the same folder.
- **`curl` and `jq`:** you send queries through the Perses proxy with `curl` and pick fields out of the JSON answers with `jq`.
- **The astrona command-line tool.**
- **A web browser:** most pages show the result in the Perses user interface as well.

Each environment runs Perses and five backends: Prometheus, Loki with a small gateway in front of it, Tempo and Pyroscope. Give your container engine at least **6 GiB** of memory. The environments also need **outbound internet** while they start: they download Helm and `percli` from GitHub, Perses and the backends from Docker Hub, and the telemetry generator from `ghcr.io`. The first start of an environment takes a few minutes. Without outbound internet, the start fails with download errors that have nothing to do with Perses.

## Reaching Perses

The Perses address is `http://perses.localtest.me:8080` everywhere. Inside the cluster, the environment points that name at the Perses Service. On your machine, the name `perses.localtest.me` is a public DNS name for `127.0.0.1`, so a port-forward makes Perses answer at the same address. Start it in a second terminal and leave it running while you work:

```sh
kubectl -n perses port-forward svc/perses 8080:8080
```

Then log `percli` in and select the project the course uses:

```sh
percli login http://perses.localtest.me:8080
percli project inventory
```

Authentication is off in this course, so `percli login` needs only the address. Some home routers block DNS answers that point at `127.0.0.1`; if your machine cannot find `perses.localtest.me`, add this line to `/etc/hosts`:

```
127.0.0.1 perses.localtest.me
```

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman. Install `jq` yourself.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS107.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It reads your Perses resources and runs their queries through the Perses proxy, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-107-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own Perses and backends. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If `percli` or `curl` cannot reach Perses, check that the port-forward is still running in your second terminal; it stops when the environment restarts. Remember also that a lab that starts with an empty panel or a datasource that answers with an error is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
