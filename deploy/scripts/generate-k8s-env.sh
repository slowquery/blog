#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_DEVTOOL="${ROOT}/helm/devtool/.env.devtool"
ENV_APP="${DEPLOY_ENV_FILE:-${ROOT}/deploy/.env.app}"
OUTPUT="${1:-}"

PLAYSTYLE_DEVTOOL="${PLAYSTYLE_DEVTOOL_ENV:-${ROOT}/../playstyle.lol/helm/devtool/.env.devtool}"

read_env() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^${key}=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- | sed 's/^"\(.*\)"$/\1/' || true
}

if [[ ! -f "$ENV_DEVTOOL" ]]; then
  echo "ERROR: $ENV_DEVTOOL 없음. npm run helm:devtool:secrets 실행 후 재시도." >&2
  exit 1
fi

MONGODB_USER="$(read_env "$ENV_DEVTOOL" MONGODB_USER)"
MONGODB_PASSWORD="$(read_env "$ENV_DEVTOOL" MONGODB_PASSWORD)"
MONGODB_DB="$(read_env "$ENV_DEVTOOL" MONGODB_DB)"
MONGODB_HOST="${MONGODB_HOST:-mongo-mongodb.devtool.svc.cluster.local}"
MONGODB_PORT="${MONGODB_PORT:-27017}"

REDIS_HOST="${REDIS_HOST:-redis-master.devtool.svc.cluster.local}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="$(read_env "$PLAYSTYLE_DEVTOOL" REDIS_PASSWORD)"
if [[ -z "$REDIS_PASSWORD" ]]; then
  REDIS_PASSWORD="$(read_env "$ENV_APP" REDIS_PASSWORD)"
fi

pick() {
  local key="$1"
  local default="${2:-}"
  local v=""
  v="$(read_env "$ENV_APP" "$key")"
  [[ -n "$v" ]] && { echo "$v"; return; }
  echo "$default"
}

SECRET_KEY="$(pick SECRET_KEY "")"
MONGO_URI="mongodb://${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_HOST}:${MONGODB_PORT}/${MONGODB_DB}"

write_env() {
  # kubectl --from-env-file: 따옴표 없이 (따옴표가 값에 포함되면 Mongo 연결 실패)
  cat <<EOF
# AUTO-GENERATED — deploy/scripts/generate-k8s-env.sh (git 커밋 금지)
NODE_ENV=production
PORT=9000
UPLOAD_PATH=/app/upload
MONGO_URI=${MONGO_URI}
MONGODB_USER=${MONGODB_USER}
MONGODB_PASSWORD=${MONGODB_PASSWORD}
MONGODB_HOST=${MONGODB_HOST}
MONGODB_PORT=${MONGODB_PORT}
MONGODB_DB=${MONGODB_DB}
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}
REDIS_PASSWORD=${REDIS_PASSWORD}
SECRET_KEY=${SECRET_KEY}
EOF
}

if [[ -n "$OUTPUT" ]]; then
  write_env > "$OUTPUT"
  echo "Wrote $OUTPUT" >&2
else
  write_env
fi
