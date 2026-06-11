#!/usr/bin/env bash
# Usage: install.sh mongodb [release-name]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART="${1:?chart name required (mongodb)}"
NAMESPACE="${HELM_NAMESPACE:-devtool}"

case "$CHART" in
  mongodb) RELEASE="${2:-mongo}" ;;
  *)
    echo "Unknown chart: $CHART" >&2
    exit 1
    ;;
esac

SUBCHART="$(awk '/^  - name: / { print $3; exit }' "$ROOT/$CHART/Chart.yaml")"
CHART_PATH="$ROOT/$CHART/charts/$SUBCHART"
SECRETS_FILE="$ROOT/$CHART/values.secrets.yaml"

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "ERROR: $SECRETS_FILE 없음. 먼저 실행: npm run helm:devtool:secrets" >&2
  exit 1
fi

unwrap_subchart_values() {
  local values_key="$1"
  local src="$2"
  local dst="$3"
  python3 - "$values_key" "$src" "$dst" <<'PY'
import sys

import yaml

values_key, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src, encoding="utf-8") as handle:
    data = yaml.safe_load(handle) or {}
if values_key in data and isinstance(data[values_key], dict):
    data = data[values_key]
with open(dst, "w", encoding="utf-8") as handle:
    yaml.dump(data, handle, default_flow_style=False, allow_unicode=True)
PY
}

"$ROOT/scripts/prepare-deps.sh" "$CHART" >/dev/null

VALUES_TMP="$(mktemp)"
SECRETS_TMP="$(mktemp)"
trap 'rm -f "$VALUES_TMP" "$SECRETS_TMP"' EXIT

unwrap_subchart_values "$SUBCHART" "$ROOT/$CHART/values.yaml" "$VALUES_TMP"
unwrap_subchart_values "$SUBCHART" "$SECRETS_FILE" "$SECRETS_TMP"

helm upgrade --install "$RELEASE" "$CHART_PATH" \
  -f "$VALUES_TMP" \
  -f "$SECRETS_TMP" \
  -n "$NAMESPACE" \
  --create-namespace

echo "Installed release '$RELEASE' from $CHART (namespace: $NAMESPACE)"
