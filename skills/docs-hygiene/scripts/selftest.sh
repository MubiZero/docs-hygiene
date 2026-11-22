#!/usr/bin/env bash
# Selftest for docs-hygiene: manifest versions, SKILL.md links, and doc_audit.sh against clean and broken-link fixtures.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
skill="$(cd "$here/.." && pwd)"
root="$(cd "$skill/../.." && pwd)"
fail=0
bad() { echo "FAIL  $*"; fail=1; }
ok()  { echo "ok    $*"; }

v1=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$root/plugin.json")
v2=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$root/.claude-plugin/plugin.json")
v3=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["plugins"][0]["version"])' "$root/.claude-plugin/marketplace.json")
[ "$v1" = "$v2" ] && [ "$v1" = "$v3" ] && ok "manifest versions agree ($v1)" || bad "manifest versions differ ($v1 / $v2 / $v3)"

out_self=$(bash "$here/doc_audit.sh" "$root")
echo "$out_self" | grep -q "Все относительные ссылки ведут на существующие файлы" && ok "docs-hygiene repo links clean" || bad "docs-hygiene has broken links"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/README.md" <<'EOF'
# Demo
See [missing doc](docs/deleted-architecture.md) for details.
EOF
out_bad=$(bash "$here/doc_audit.sh" "$tmp")
echo "$out_bad" | grep -q "БИТАЯ ССЫЛКА: README.md -> docs/deleted-architecture.md" && ok "doc_audit.sh catches broken relative link" || bad "doc_audit.sh missed broken link"

[ "$fail" = 0 ] && echo "ALL OK" || exit 1
