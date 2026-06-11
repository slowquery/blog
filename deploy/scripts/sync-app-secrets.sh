#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_K8S="${ROOT}/deploy/.env.k8s"
NAMESPACE="${BLOG_NAMESPACE:-blog}"

PLAYSTYLE_DEVTOOL="${PLAYSTYLE_DEVTOOL_ENV:-${ROOT}/../playstyle.lol/helm/devtool/.env.devtool}"

read_env() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | tail -1 | cut -d= -f2- || true
}

HARBOR_USER=""
HARBOR_PASSWORD=""
if [[ -f "$PLAYSTYLE_DEVTOOL" ]]; then
  HARBOR_USER="$(read_env "$PLAYSTYLE_DEVTOOL" HARBOR_ADMIN_USER)"
  HARBOR_PASSWORD="$(read_env "$PLAYSTYLE_DEVTOOL" HARBOR_ADMIN_PASSWORD)"
fi

echo "==> Generate K8s .env"
bash "${ROOT}/deploy/scripts/generate-k8s-env.sh" "$ENV_K8S"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Secret blog-app-env"
kubectl -n "$NAMESPACE" create secret generic blog-app-env \
  --from-env-file="$ENV_K8S" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ -n "$HARBOR_USER" && -n "$HARBOR_PASSWORD" ]]; then
  kubectl -n "$NAMESPACE" create secret docker-registry harbor-registry \
    --docker-server=image.registry.playstyle.lol \
    --docker-username="$HARBOR_USER" \
    --docker-password="$HARBOR_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "WARNING: Harbor pull secret 스킵 — playstyle devtool .env.devtool 없음" >&2
fi

echo "OK: namespace=$NAMESPACE secret=blog-app-env"
