#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_DEVTOOL="${ROOT}/helm/devtool/.env.devtool"
DUMP_ZIP="${DUMP_ZIP:-${ROOT}/dump.zip}"
MONGO_NAMESPACE="${MONGO_NAMESPACE:-devtool}"
MONGO_RELEASE="${MONGO_RELEASE:-mongo}"

read_env() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- || true
}

if [[ ! -f "$ENV_DEVTOOL" ]]; then
  echo "ERROR: $ENV_DEVTOOL 없음" >&2
  exit 1
fi

if [[ ! -f "$DUMP_ZIP" ]]; then
  echo "ERROR: dump 없음: $DUMP_ZIP" >&2
  exit 1
fi

MONGODB_ROOT_PASSWORD="$(read_env "$ENV_DEVTOOL" MONGODB_ROOT_PASSWORD)"
if [[ -z "$MONGODB_ROOT_PASSWORD" ]]; then
  echo "ERROR: MONGODB_ROOT_PASSWORD 비어 있음" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "==> unzip $DUMP_ZIP"
unzip -q "$DUMP_ZIP" -d "$WORK_DIR"

DUMP_DIR="$WORK_DIR/dump"
if [[ ! -d "$DUMP_DIR/blog" ]]; then
  echo "ERROR: dump/blog 디렉터리 없음" >&2
  exit 1
fi

POD="$(kubectl -n "$MONGO_NAMESPACE" get pod -l "app.kubernetes.io/name=mongodb,app.kubernetes.io/instance=${MONGO_RELEASE}" \
  -o jsonpath='{.items[0].metadata.name}')"
if [[ -z "$POD" ]]; then
  echo "ERROR: MongoDB Pod 없음" >&2
  exit 1
fi

echo "==> kubectl cp dump -> ${MONGO_NAMESPACE}/${POD}:/tmp/dump"
kubectl -n "$MONGO_NAMESPACE" exec "$POD" -- rm -rf /tmp/dump
kubectl cp "$DUMP_DIR" "${MONGO_NAMESPACE}/${POD}:/tmp/dump"

echo "==> mongorestore blog.* (--drop) via pod exec"
kubectl -n "$MONGO_NAMESPACE" exec "$POD" -- mongorestore \
  --uri="mongodb://root:${MONGODB_ROOT_PASSWORD}@127.0.0.1:27017/?authSource=admin" \
  --drop --nsInclude='blog.*' /tmp/dump

echo "==> verify counts"
kubectl -n "$MONGO_NAMESPACE" exec "$POD" -- mongosh --quiet \
  -u root -p "$MONGODB_ROOT_PASSWORD" --authenticationDatabase admin \
  --eval 'const b=db.getSiblingDB("blog"); const p=b.posts.countDocuments(); print("posts="+p); if(p<1) quit(2);'

echo "OK: mongodb restore complete"
