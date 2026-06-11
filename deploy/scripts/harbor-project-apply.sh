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

grant_ci_robot_push() {
  local project="$1"
  local ci_robot_id
  ci_robot_id="$(curl -sS "${AUTH[@]}" "${HARBOR_API}/robots?page_size=50" \
    | python3 -c "import json,sys; robots=json.load(sys.stdin); print(next((r['id'] for r in robots if r.get('name')=='robot\$github-action-user'), ''))" 2>/dev/null || true)"

  if [[ -z "$ci_robot_id" ]]; then
    echo "SKIP: CI robot robot\$github-action-user not found"
    return 0
  fi

  export HARBOR_ADMIN_USER HARBOR_ADMIN_PASSWORD HARBOR_API
  local robot_json
  robot_json="$(curl -sS "${AUTH[@]}" "${HARBOR_API}/robots/${ci_robot_id}")"
  python3 - "$ci_robot_id" "$project" "$robot_json" <<'PY'
import base64
import json
import os
import sys
import urllib.request

robot_id, project, robot_json = sys.argv[1], sys.argv[2], sys.argv[3]
robot = json.loads(robot_json)
project_access = [
    {"action": "read", "resource": "project"},
    {"action": "list", "resource": "repository"},
    {"action": "pull", "resource": "repository"},
    {"action": "push", "resource": "repository"},
    {"action": "read", "resource": "repository"},
    {"action": "update", "resource": "repository"},
]
perms = robot["permissions"]
if any(p.get("kind") == "project" and p.get("namespace") == project for p in perms):
    print(f"OK: CI robot already has project '{project}' permission")
    sys.exit(0)

perms.append({"access": project_access, "kind": "project", "namespace": project})
body = json.dumps({
    "name": robot["name"],
    "disable": robot["disable"],
    "duration": robot["duration"],
    "level": robot["level"],
    "permissions": perms,
}).encode()
user = os.environ["HARBOR_ADMIN_USER"]
password = os.environ["HARBOR_ADMIN_PASSWORD"]
api = os.environ["HARBOR_API"]
auth = base64.b64encode(f"{user}:{password}".encode()).decode()
req = urllib.request.Request(
    f"{api}/robots/{robot_id}",
    data=body,
    headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"},
    method="PUT",
)
with urllib.request.urlopen(req) as resp:
    print(f"OK: granted CI robot push to project '{project}' (HTTP {resp.status})")
PY
}

code="$(curl -sS "${AUTH[@]}" -o /tmp/harbor-project.json -w '%{http_code}' \
  "${HARBOR_API}/projects/${HARBOR_PROJECT}")"

if [[ "$code" == "200" ]]; then
  echo "OK: Harbor project '${HARBOR_PROJECT}' already exists"
elif [[ "$code" == "404" ]]; then
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
else
  echo "ERROR: GET project HTTP $code" >&2
  cat /tmp/harbor-project.json >&2
  exit 1
fi

grant_ci_robot_push "${HARBOR_PROJECT}"
