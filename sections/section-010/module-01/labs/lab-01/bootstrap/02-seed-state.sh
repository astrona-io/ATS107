#!/usr/bin/env bash
# Creates the starting state for ats-107-lab-010-01.
#
# The fixed state is NOT created here — producing it is the task.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_DIR="$SCRIPT_DIR/../manifests/seed"
[ -d "$SEED_DIR" ] && apply_dir "$SEED_DIR"

record_baseline global-loki-spec "$(perses_get /api/v1/globaldatasources/loki | jq -cS .spec)"
echo "[lab] The global Loki datasource has no credentials; the gateway answers 401 through it."

echo "[lab] Starting state ready."
