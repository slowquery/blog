#!/usr/bin/env bash
# blog devtool MongoDB — 28자 비밀번호 → mongodb/values.secrets.yaml + .env.devtool
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env.devtool"
MARKER="# AUTO-GENERATED — helm/devtool/scripts/devtool-secrets-generate.sh"

REGEN_ALL=0
if [[ "${DEVTOOL_SECRETS_FORCE:-}" == "1" ]]; then
  REGEN_ALL=1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl 이 필요합니다."
  exit 1
fi

gen_password_28() {
  local pw=""
  while [[ ${#pw} -ne 28 ]]; do
    pw="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 28)"
  done
  echo "$pw"
}

read_env_value() {
  local key="$1"
  if [[ ! -f "$ENV_FILE" ]]; then
    return 0
  fi
  grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2- || true
}

read_yaml_password() {
  local file="${ROOT}/mongodb/values.secrets.yaml"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  python3 - "$file" <<'PY'
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as handle:
    data = yaml.safe_load(handle) or {}
auth = (data.get("mongodb") or {}).get("auth") or {}
root = auth.get("rootPassword") or ""
passwords = auth.get("passwords") or []
user_pw = passwords[0] if passwords else ""
print(f"{root}\t{user_pw}")
PY
}

resolve_password() {
  local env_key="$1"
  local yaml_slot="$2"
  local from_env=""
  local from_yaml=""

  if [[ "$REGEN_ALL" == "1" ]]; then
    echo "  new  ${env_key}" >&2
    gen_password_28
    return 0
  fi

  from_env="$(read_env_value "$env_key")"
  yaml_line="$(read_yaml_password)"
  if [[ "$yaml_slot" == "root" ]]; then
    from_yaml="${yaml_line%%$'\t'*}"
  else
    from_yaml="${yaml_line#*$'\t'}"
  fi

  if [[ -n "$from_env" ]]; then
    echo "  keep ${env_key} (from .env.devtool)" >&2
    echo "$from_env"
    return 0
  fi
  if [[ -n "$from_yaml" ]]; then
    echo "  keep ${env_key} (from values.secrets.yaml)" >&2
    echo "$from_yaml"
    return 0
  fi

  echo "  new  ${env_key}" >&2
  gen_password_28
}

write_if_changed() {
  local rel_path="$1"
  local new_content="$2"
  local file="${ROOT}/${rel_path}"
  local new_file=""
  new_file="$(mktemp)"
  printf '%s' "$new_content" > "$new_file"
  if [[ -f "$file" ]] && cmp -s "$file" "$new_file"; then
    rm -f "$new_file"
    echo "  unchanged ${rel_path}" >&2
    return 1
  fi
  umask 077
  mv "$new_file" "$file"
  echo "  wrote ${rel_path}" >&2
  return 0
}

MONGODB_USER="${MONGODB_USER:-$(read_env_value MONGODB_USER)}"
MONGODB_USER="${MONGODB_USER:-antiweb}"
MONGODB_DB="${MONGODB_DB:-$(read_env_value MONGODB_DB)}"
MONGODB_DB="${MONGODB_DB:-blog}"
MONGODB_PORT="${MONGODB_PORT:-$(read_env_value MONGODB_PORT)}"
MONGODB_PORT="${MONGODB_PORT:-27017}"

MONGODB_ROOT_PASSWORD="$(resolve_password MONGODB_ROOT_PASSWORD root)"
MONGODB_PASSWORD="$(resolve_password MONGODB_PASSWORD user)"

MONGO_SECRETS="$(cat <<EOF
${MARKER}
mongodb:
  auth:
    rootPassword: ${MONGODB_ROOT_PASSWORD}
    passwords:
      - ${MONGODB_PASSWORD}
EOF
)"

ENV_CONTENT="$(cat <<EOF
${MARKER}
MONGODB_USER=${MONGODB_USER}
MONGODB_DB=${MONGODB_DB}
MONGODB_PORT=${MONGODB_PORT}
MONGODB_ROOT_PASSWORD=${MONGODB_ROOT_PASSWORD}
MONGODB_PASSWORD=${MONGODB_PASSWORD}
EOF
)"

changed=0
if write_if_changed "mongodb/values.secrets.yaml" "$MONGO_SECRETS"; then
  changed=1
fi
if write_if_changed ".env.devtool" "$ENV_CONTENT"; then
  changed=1
fi

if [[ "$changed" == "0" ]]; then
  echo "변경 없음 — 기존 devtool secrets 를 그대로 사용합니다."
else
  echo "작성 완료: helm/devtool/.env.devtool, helm/devtool/mongodb/values.secrets.yaml"
  echo "다음: npm run helm:devtool:install:mongodb"
fi
