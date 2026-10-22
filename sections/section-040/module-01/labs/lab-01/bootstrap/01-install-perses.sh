#!/usr/bin/env bash
# Installs Helm 3.22.1, percli 0.54.0, the observability stack and Perses v0.54.0,
# then creates the project inventory and the global datasources.
#
# Graded lab bootstrap: this prepares the environment ONLY. It never creates
# the objects the task asks for.
set -euo pipefail

export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
PERSES_API="http://perses.perses:8080"
PROJECT="inventory"

# Runs a command in the tester pod, which reaches Perses and every backend.
tester() { kubectl -n observability exec -i deploy/tester -- "$@"; }

# perses_get PATH: GET from the Perses API; fails on an HTTP error.
perses_get() { tester curl -fsS "$PERSES_API$1"; }

# perses_send METHOD PATH: sends the JSON on stdin to the Perses API.
perses_send() {
  tester curl -fsS -X "$1" -H 'Content-Type: application/json' --data-binary @- "$PERSES_API$2"
}

# http_status METHOD PATH: prints only the HTTP status code Perses answers with.
http_status() { tester curl -s -o /dev/null -w '%{http_code}' -X "$1" "$PERSES_API$2"; }

# collection_for: reads a resource on stdin and prints its API collection path.
collection_for() {
  jq -r 'if .kind == "Project" then "/api/v1/projects"
    elif .kind == "GlobalDatasource" then "/api/v1/globaldatasources"
    elif .kind == "GlobalSecret" then "/api/v1/globalsecrets"
    elif .kind == "GlobalVariable" then "/api/v1/globalvariables"
    elif .kind == "Datasource" then "/api/v1/projects/\(.metadata.project)/datasources"
    elif .kind == "Secret" then "/api/v1/projects/\(.metadata.project)/secrets"
    elif .kind == "Variable" then "/api/v1/projects/\(.metadata.project)/variables"
    elif .kind == "Dashboard" then "/api/v1/projects/\(.metadata.project)/dashboards"
    else error("unknown kind \(.kind)") end'
}

# apply_resource FILE: creates the resource, or replaces it when it exists.
apply_resource() {
  local json collection name
  json="$(cat "$1")"
  collection="$(printf '%s' "$json" | collection_for)"
  name="$(printf '%s' "$json" | jq -r '.metadata.name')"
  if ! printf '%s' "$json" | perses_send POST "$collection" >/dev/null 2>&1; then
    printf '%s' "$json" | perses_send PUT "$collection/$name" >/dev/null
  fi
}

# apply_dir DIR: applies every *.json file of a folder in name order.
apply_dir() {
  local file
  for file in $(ls "$1"/*.json 2>/dev/null | sort); do
    apply_resource "$file"
  done
}

# record_baseline KEY VALUE: keeps a value the graders compare against later.
record_baseline() {
  kubectl -n perses get configmap lab-baseline >/dev/null 2>&1 || \
    kubectl -n perses create configmap lab-baseline >/dev/null
  kubectl -n perses patch configmap lab-baseline --type merge \
    -p "$(jq -nc --arg key "$1" --arg value "$2" '{data: {($key): $value}}')" >/dev/null
}

# baseline KEY: prints a value recorded by the seed script.
baseline() { kubectl -n perses get configmap lab-baseline -o json | jq -r --arg key "$1" '.data[$key] // empty'; }

# proxy_base NAME: the proxy path of a datasource; a project datasource of
# that name wins over a global one, as it does in a dashboard.
proxy_base() {
  if [ "$(http_status GET "/api/v1/projects/$PROJECT/datasources/$1")" = "200" ]; then
    echo "/proxy/projects/$PROJECT/datasources/$1"
  else
    echo "/proxy/globaldatasources/$1"
  fi
}

# prom_series EXPR [DATASOURCE]: number of series an instant PromQL query returns.
prom_series() {
  local base; base="$(proxy_base "${2:-prometheus}")"
  tester curl -s -X POST "$PERSES_API$base/api/v1/query" --data-urlencode "query=$1" \
    | jq -r '(.data.result // []) | length' 2>/dev/null || echo 0
}

# prom_label_values LABEL MATCHER [DATASOURCE]: label values, one per line.
prom_label_values() {
  local base; base="$(proxy_base "${3:-prometheus}")"
  tester curl -s -G "$PERSES_API$base/api/v1/label/$1/values" --data-urlencode "match[]=$2" \
    | jq -r '(.data // [])[]' 2>/dev/null
}

# loki_streams QUERY [DATASOURCE]: number of log streams a LogQL query returns for the last hour.
loki_streams() {
  local base; base="$(proxy_base "${2:-loki}")"
  tester curl -s -G "$PERSES_API$base/loki/api/v1/query_range" \
    --data-urlencode "query=$1" --data-urlencode "limit=20" \
    | jq -r '(.data.result // []) | length' 2>/dev/null || echo 0
}

# tempo_traces QUERY [DATASOURCE]: number of traces a TraceQL search returns.
tempo_traces() {
  local base; base="$(proxy_base "${2:-tempo}")"
  tester curl -s -G "$PERSES_API$base/api/search" --data-urlencode "q=$1" --data-urlencode "limit=20" \
    | jq -r '(.traces // []) | length' 2>/dev/null || echo 0
}

# pyroscope_types [DATASOURCE]: number of profile types Pyroscope reports.
pyroscope_types() {
  local base; base="$(proxy_base "${1:-pyroscope}")"
  tester curl -s -X POST -H 'Content-Type: application/json' -d '{}' \
    "$PERSES_API$base/querier.v1.QuerierService/ProfileTypes" \
    | jq -r '(.profileTypes // []) | length' 2>/dev/null || echo 0
}

# dashboard NAME: the dashboard's JSON from the Perses API.
dashboard() { perses_get "/api/v1/projects/$PROJECT/dashboards/$1"; }

# panel_queries: reads a dashboard on stdin and prints one line per query:
# panel key, panel kind, query kind, query plugin kind, datasource name
# ("-" when the query names none), and the query text (base64), separated by
# tabs. No field is ever empty, because `read` merges empty tab fields.
panel_queries() {
  jq -r '.spec.panels | to_entries[] | .key as $key | .value.spec as $panel
    | ($panel.queries // [])[]
    | [$key, $panel.plugin.kind, .kind, .spec.plugin.kind,
       (.spec.plugin.spec.datasource | if type == "object" then (.name // "-") elif type == "string" then . else "-" end),
       ((.spec.plugin.spec.query // .spec.plugin.spec.profileType // "") | @base64)] | @tsv'
}

# substitute TEXT ENV SERVICE: writes single values for $env and $service
# (and ${env}, ${service}, with or without a format) into a query.
substitute() {
  ENV_VALUE="$2" SERVICE_VALUE="$3" perl -pe '
    s/\$\{env(?::[a-z]+)?\}/$ENV{ENV_VALUE}/g; s/\$env\b/$ENV{ENV_VALUE}/g;
    s/\$\{service(?::[a-z]+)?\}/$ENV{SERVICE_VALUE}/g; s/\$service\b/$ENV{SERVICE_VALUE}/g;' <<< "$1"
}

# default_datasource QUERY_PLUGIN_KIND: the global default datasource name a query without a name uses.
default_datasource() {
  case "$1" in
    Prometheus*) echo prometheus ;;
    Loki*) echo loki ;;
    Tempo*) echo tempo ;;
    Pyroscope*) echo pyroscope ;;
  esac
}

# datasource_for PLUGIN_KIND NAME: the datasource a query really uses
# (a variable such as $prometheus resolves to the default in graders).
datasource_for() {
  case "$2" in
    ""|-|\$*) default_datasource "$1" ;;
    *) echo "$2" ;;
  esac
}

# query_returns_data PLUGIN_KIND DATASOURCE QUERY: exit 0 when the query returns data.
query_returns_data() {
  local count=0
  case "$1" in
    PrometheusTimeSeriesQuery) count="$(prom_series "$3" "$2")" ;;
    LokiLogQuery|LokiTimeSeriesQuery) count="$(loki_streams "$3" "$2")" ;;
    TempoTraceQuery) count="$(tempo_traces "$3" "$2")" ;;
    PyroscopeProfileQuery) count="$(pyroscope_types "$2")" ;;
  esac
  [ "${count:-0}" -gt 0 ] 2>/dev/null
}

LOG_TAG="lab"
HELM_VERSION="3.22.1"
PERSES_VERSION="0.54.0"
PERSES_CHART_VERSION="0.23.3"
PERSES_HOST="perses.localtest.me"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pin the tools rather than accepting whatever is on the machine.
have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  echo "[$LOG_TAG] Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi
# percli ships in the Perses release archive, next to the server binary.
have_percli=""
command -v percli >/dev/null 2>&1 && have_percli=$(percli version 2>/dev/null | awk '/[Vv]ersion/{print $NF; exit}' | sed 's/^v//')
if [ "$have_percli" != "$PERSES_VERSION" ]; then
  echo "[$LOG_TAG] Downloading percli ${PERSES_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/perses/perses/releases/download/v${PERSES_VERSION}/perses_${PERSES_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" percli
  install -m 0755 "$WORK/percli" "$BIN_DIR/percli"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# One address for the reader's machine and the cluster: perses.localtest.me
# resolves to 127.0.0.1 on the machine (reached through a port-forward), and
# this CoreDNS block sends the same name to the Perses Service in the cluster.
# The answer is rewritten back to the asked name: Go programs ignore DNS
# answers whose name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$PERSES_HOST"; then
  echo "[$LOG_TAG] Adding the CoreDNS rewrite for ${PERSES_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex perses\\.localtest\\.me perses.perses.svc.cluster.local"
        print "        answer name perses\\.perses\\.svc\\.cluster\\.local perses.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

# lab-start.yaml is also listed under bootstrap.manifests in config.yaml, so it
# may already be applied. kubectl apply is idempotent.
echo "[$LOG_TAG] Starting the observability stack..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
for deployment in prometheus loki loki-gateway tempo pyroscope tester \
    telemetry-production-checkout telemetry-production-payments telemetry-staging-checkout; do
  kubectl -n observability rollout status "deployment/$deployment" --timeout=600s
done

echo "[$LOG_TAG] Installing Perses (chart ${PERSES_CHART_VERSION})..."
helm repo add perses https://perses.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update perses >/dev/null
helm upgrade --install perses perses/perses --version "$PERSES_CHART_VERSION" \
  --namespace perses --create-namespace \
  --values "$MANIFEST_DIR/perses-values.yaml" \
  --wait --timeout 10m

for _ in $(seq 1 60); do
  [ "$(http_status GET /api/v1/projects)" = "200" ] && break
  sleep 5
done

echo "[$LOG_TAG] Creating the project and the datasources..."
apply_dir "$MANIFEST_DIR/perses"

echo "[$LOG_TAG] Waiting for telemetry to arrive in Prometheus..."
for _ in $(seq 1 60); do
  [ "$(prom_series 'app_requests_total')" -gt 0 ] 2>/dev/null && break
  sleep 5
done

echo "[lab] Perses and the stack are ready."
