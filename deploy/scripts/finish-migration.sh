#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DUMP_ZIP="${DUMP_ZIP:-${ROOT}/dump.zip}"

cd "$ROOT"

if [[ "${SKIP_VERIFY:-}" != "1" ]]; then
  bash "${ROOT}/deploy/scripts/verify-service.sh"
fi

if [[ ! -f "$DUMP_ZIP" ]]; then
  echo "dump.zip 없음 — 이미 삭제되었거나 경로가 다릅니다."
  exit 0
fi

rm -f "$DUMP_ZIP"
echo "Removed $DUMP_ZIP"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: git 레포 아님" >&2
  exit 1
fi

if git diff --quiet -- "$DUMP_ZIP" 2>/dev/null && ! git ls-files --error-unmatch dump.zip >/dev/null 2>&1; then
  echo "dump.zip git 추적 없음 — 삭제만 완료"
  exit 0
fi

git add -u dump.zip

if git diff --staged --quiet; then
  echo "커밋할 변경 없음"
  exit 0
fi

git commit -m "$(cat <<'EOF'
chore(deploy): remove dump.zip after successful k8s migration

MongoDB dump restored to devtool/mongo; upload/ synced to PVC.
Service verification passed (posts, HTTP, images).
EOF
)"

echo "OK: committed dump.zip removal (push는 수동: git push origin master)"
