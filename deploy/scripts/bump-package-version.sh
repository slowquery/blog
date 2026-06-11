#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?version required}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

node - "$VERSION" "$ROOT/package.json" <<'NODE'
const fs = require('fs');
const [version, pkgPath] = process.argv.slice(2);
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
pkg.version = version;
fs.writeFileSync(pkgPath, `${JSON.stringify(pkg, null, 2)}\n`);
NODE

echo "package.json -> v${VERSION}"
