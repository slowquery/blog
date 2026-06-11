#!/usr/bin/env bash
set -euo pipefail

GATEWAY_NS="${GATEWAY_NS:-istio-system}"
GATEWAY_NAME="${GATEWAY_NAME:-devtool}"
HOSTS=(imustdo.work www.imustdo.work)

current="$(kubectl -n "$GATEWAY_NS" get gateway.networking.istio.io "$GATEWAY_NAME" -o json)"

PATCH="$(python3 - "$current" "${HOSTS[@]}" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
new_hosts = sys.argv[2:]
servers = data["spec"].get("servers") or []
if not servers:
    raise SystemExit("no servers in gateway")
hosts = list(servers[0].get("hosts") or [])
added = [h for h in new_hosts if h not in hosts]
if not added:
    print("SKIP")
    sys.exit(0)
hosts.extend(added)
servers[0]["hosts"] = hosts
print(json.dumps({"spec": {"servers": servers}}))
print("adding: " + ", ".join(added), file=sys.stderr)
PY
)"

if [[ "$PATCH" == "SKIP" ]]; then
  echo "hosts already present — no change"
  exit 0
fi

echo "==> patch gateway ${GATEWAY_NS}/${GATEWAY_NAME}"
kubectl -n "$GATEWAY_NS" patch gateway.networking.istio.io "$GATEWAY_NAME" --type merge -p "$PATCH"
echo "OK"
