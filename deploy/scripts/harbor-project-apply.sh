#!/usr/bin/env bash
# Harbor blog 프로젝트 생성 (playstyle devtool Harbor credential 사용)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAYSTYLE_DEVTOOL="${PLAYSTYLE_DEVTOOL_ENV:-${ROOT}/../playstyle.lol/helm/devtool/.env.devtool}"

HARBOR_URL="${HARBOR_URL:-http://harbor.playstyle.lol}"
HARBOR_PROJECT="${HARBOR_PROJECT:-blog}"

read_env() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- || true
}

HARBOR_ADMIN_USER="$(read_env "$PLAYSTYLE_DEVTOOL" HARBOR_ADMIN_USER)"
HARBOR_ADMIN_PASSWORD="$(read_env "$PLAYSTYLE_DEVTOOL" HARBOR_ADMIN_PASSWORD)"
HARBOR_ADMIN_USER="${HARBOR_ADMIN_USER:-admin}"

if [[ -z "$HARBOR_ADMIN_PASSWORD" ]]; then
  echo "ERROR: HARBOR_ADMIN_PASSWORD 없음 ($PLAYSTYLE_DEVTOOL)" >&2
  exit 1
fi

HARBOR_API="${HARBOR_URL%/}/api/v2.0"
AUTH=(-u "${HARBOR_ADMIN_USER}:${HARBOR_ADMIN_PASSWORD}")

code="$(curl -sS "${AUTH[@]}" -o /tmp/harbor-project.json -w '%{http_code}' \
  "${HARBOR_API}/projects/${HARBOR_PROJECT}")"

if [[ "$code" == "200" ]]; then
  echo "OK: Harbor project '${HARBOR_PROJECT}' already exists"
  exit 0
fi

if [[ "$code" != "404" ]]; then
  echo "ERROR: GET project HTTP $code" >&2
  cat /tmp/harbor-project.json >&2
  exit 1
fi

body='{"project_name":"'"${HARBOR_PROJECT}"'","public":false}'
code="$(curl -sS "${AUTH[@]}" -X POST -H 'Content-Type: application/json' \
  -d "$body" -o /tmp/harbor-create.json -w '%{http_code}' \
  "${HARBOR_API}/projects")"

if [[ "$code" != "201" && "$code" != "200" ]]; then
  echo "ERROR: CREATE project HTTP $code" >&2
  cat /tmp/harbor-create.json >&2
  exit 1
fi

echo "OK: created Harbor project '${HARBOR_PROJECT}'"
