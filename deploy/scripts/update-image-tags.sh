#!/usr/bin/env bash
# deploy/helm/application/values.yaml 이미지 태그 갱신
set -euo pipefail

VERSION="${1:?version required}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALUES="${ROOT}/deploy/helm/application/values.yaml"

python3 - "$VERSION" "$VALUES" <<'PY'
import sys

import yaml

version, path = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    data = yaml.safe_load(handle) or {}

data["appVersion"] = version
images = data.setdefault("images", {})
app = images.setdefault("application", {})
app["tag"] = version

with open(path, "w", encoding="utf-8") as handle:
    yaml.dump(data, handle, default_flow_style=False, allow_unicode=True, sort_keys=False)
PY

echo "Updated ${VALUES} -> v${VERSION}"
