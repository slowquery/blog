#!/usr/bin/env bash
# in-cluster 검증 (기본). 외부 DNS(imustdo.work) 검증은 VERIFY_EXTERNAL_DNS=1 필요.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_DEVTOOL="${ROOT}/helm/devtool/.env.devtool"
NAMESPACE="${BLOG_NAMESPACE:-blog}"
MONGO_NAMESPACE="${MONGO_NAMESPACE:-devtool}"
MONGO_RELEASE="${MONGO_RELEASE:-mongo}"

VERIFY_URL="${VERIFY_URL:-http://application.${NAMESPACE}.svc.cluster.local:9000}"
VERIFY_IMAGE="${VERIFY_IMAGE:-2018-01-27_17-27-19_096.png}"

read_env() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- || true
}

cluster_http_ok() {
  local url="$1"
  local code
  local pod_name="blog-http-check-$$"
  code="$(kubectl run "$pod_name" --rm -i --restart=Never -n "$NAMESPACE" \
    --image=curlimages/curl:8.5.0 --command -- \
    curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 "$url" 2>/dev/null \
    | tr -d '\r' | grep -oE '[0-9]{3}' | head -1 || echo 000)"
  [[ "$code" == "200" ]]
}

echo "==> MongoDB document counts"
MONGODB_ROOT_PASSWORD="$(read_env "$ENV_DEVTOOL" MONGODB_ROOT_PASSWORD)"
POD="$(kubectl -n "$MONGO_NAMESPACE" get pod -l "app.kubernetes.io/name=mongodb,app.kubernetes.io/instance=${MONGO_RELEASE}" \
  -o jsonpath='{.items[0].metadata.name}')"
kubectl -n "$MONGO_NAMESPACE" exec "$POD" -- mongosh --quiet \
  -u root -p "$MONGODB_ROOT_PASSWORD" --authenticationDatabase admin \
  --eval 'const b=db.getSiblingDB("blog"); print("posts="+b.posts.countDocuments()); if(b.posts.countDocuments()<1) quit(2);'

echo "==> HTTP GET ${VERIFY_URL}/ (in-cluster curl pod)"
if ! cluster_http_ok "${VERIFY_URL}/"; then
  echo "ERROR: root path not 200" >&2
  exit 1
fi

echo "==> HTTP GET ${VERIFY_URL}/image/${VERIFY_IMAGE}"
if ! cluster_http_ok "${VERIFY_URL}/image/${VERIFY_IMAGE}"; then
  echo "ERROR: image not 200 — upload sync 확인" >&2
  exit 1
fi

if [[ "${VERIFY_EXTERNAL_DNS:-}" == "1" ]]; then
  EXT_HTTP="${VERIFY_HOST:-http://imustdo.work}"
  echo "==> External DNS check ${EXT_HTTP}"
  ext_code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 15 "${EXT_HTTP}/" || echo 000)"
  if [[ "$ext_code" != "200" ]]; then
    echo "ERROR: external URL HTTP ${ext_code} — DNS/ Gateway 확인" >&2
    exit 1
  fi
  if [[ "${VERIFY_HTTPS:-}" == "1" ]]; then
    EXT_HTTPS="${VERIFY_HOST_HTTPS:-https://imustdo.work}"
    echo "==> External HTTPS check ${EXT_HTTPS}"
    https_code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 15 "${EXT_HTTPS}/" || echo 000)"
    if [[ "$https_code" != "200" ]]; then
      echo "WARNING: HTTPS ${https_code} — Cloudflare SSL 모드(Flexible/Full) 확인" >&2
    fi
  else
    echo "TIP: HTTPS 검증은 Cloudflare SSL 설정 후 VERIFY_HTTPS=1 로 재실행"
  fi
else
  echo "SKIP: external DNS (imustdo.work) — DNS 변경 후 VERIFY_EXTERNAL_DNS=1 로 재실행"
fi

echo "OK: service verification passed"
