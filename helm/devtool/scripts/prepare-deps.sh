#!/usr/bin/env bash
# Bitnami dependency .tgz 를 charts/<name>/ 디렉터리로 풀어 Helm install/template 이 동작하게 합니다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

prepare_one() {
  local name="$1"
  local dir="$ROOT/$name"

  echo "==> $name: helm dependency update"
  (cd "$dir" && helm dependency update)

  local subchart
  subchart="$(awk '/^  - name: / { print $3; exit }' "$dir/Chart.yaml")"
  if [[ -z "$subchart" ]]; then
    echo "    skip (native chart, no dependency)"
    return 0
  fi

  local tgz
  shopt -s nullglob
  for tgz in "$dir"/charts/*.tgz; do
    echo "    extract $subchart"
    rm -rf "$dir/charts/$subchart"
    tar -xzf "$tgz" -C "$dir/charts/"
  done
  shopt -u nullglob
}

if [[ $# -gt 0 ]]; then
  for chart in "$@"; do
    prepare_one "$chart"
  done
else
  prepare_one mongodb
fi
