#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "==> Sync app secrets"
bash "${ROOT}/deploy/scripts/sync-app-secrets.sh"

echo "==> Argo CD repository credential (HTTPS)"
bash "${ROOT}/deploy/scripts/argocd-repo-secret-apply.sh"

echo "==> Apply Argo CD AppProject + Application"
kubectl apply -f "${ROOT}/deploy/argocd/project-blog.yaml"
kubectl apply -f "${ROOT}/deploy/argocd/application-blog.yaml"

echo "==> Done. Argo CD UI: http://deploy.playstyle.lol → Application blog"
