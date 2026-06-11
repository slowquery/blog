#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPLOAD_SRC="${UPLOAD_SRC:-${ROOT}/upload}"
NAMESPACE="${BLOG_NAMESPACE:-blog}"
APP_LABEL="${APP_LABEL:-application}"

if [[ ! -d "$UPLOAD_SRC" ]]; then
  echo "ERROR: upload 디렉터리 없음: $UPLOAD_SRC" >&2
  exit 1
fi

POD="$(kubectl -n "$NAMESPACE" get pod -l "app.kubernetes.io/name=${APP_LABEL}" \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

if [[ -z "$POD" ]]; then
  echo "ERROR: Running Pod 없음 (namespace=$NAMESPACE label=$APP_LABEL)" >&2
  exit 1
fi

MOUNT_PATH="${UPLOAD_MOUNT:-/app/upload}"

echo "==> kubectl cp $UPLOAD_SRC -> ${NAMESPACE}/${POD}:${MOUNT_PATH}/"
kubectl -n "$NAMESPACE" exec "$POD" -- mkdir -p "$MOUNT_PATH"
kubectl cp "$UPLOAD_SRC/." "${NAMESPACE}/${POD}:${MOUNT_PATH}/"

COUNT="$(kubectl -n "$NAMESPACE" exec "$POD" -- sh -c "ls -1 ${MOUNT_PATH} | wc -l")"
echo "OK: ${COUNT} files in ${MOUNT_PATH}"
