#!/usr/bin/env bash
# Argo CD — blog 레포 HTTPS credential (gh auth 또는 GITHUB_TOKEN)
set -euo pipefail

NAMESPACE="${ARGOCD_NAMESPACE:-devtool}"
REPO_URL="${ARGOCD_REPO_URL:-https://github.com/slowquery/blog.git}"
SECRET_NAME="${ARGOCD_REPO_SECRET_NAME:-repo-blog-https}"

TOKEN="${GITHUB_TOKEN:-}"
if [[ -z "$TOKEN" ]] && command -v gh >/dev/null 2>&1; then
  TOKEN="$(gh auth token 2>/dev/null || true)"
fi

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: GITHUB_TOKEN 또는 gh auth login 필요" >&2
  exit 1
fi

kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal=type=git \
  --from-literal=url="$REPO_URL" \
  --from-literal=username=git \
  --from-literal=password="$TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" label secret "$SECRET_NAME" \
  argocd.argoproj.io/secret-type=repository \
  --overwrite

echo "OK: Argo CD repository $REPO_URL (secret=$SECRET_NAME)"
