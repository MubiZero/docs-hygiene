#!/usr/bin/env bash
# Selftest for docs-hygiene 2.0: manifest versions, rules/AGENTS.md, templates, doc_audit.sh (broken links + orphans + split AGENTS/CLAUDE) and doc_map.sh.
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

[ -f "$root/rules/AGENTS.md" ] && ok "continuous hygiene rules/AGENTS.md present" || bad "missing rules/AGENTS.md"
for t in DOCS-MOC.md AGENTS-TEMPLATE.md STATUS-TEMPLATE.md ADR-TEMPLATE.md; do
  [ -f "$skill/templates/$t" ] && ok "template $t present" || bad "missing template $t"
done

out_self=$(bash "$here/doc_audit.sh" "$root")
echo "$out_self" | grep -q "Все относительные ссылки ведут на существующие файлы" && ok "docs-hygiene repo links clean" || bad "docs-hygiene has broken links"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/docs/decisions" "$tmp/cmd/api"
touch "$tmp/cmd/api/main.go"
cat > "$tmp/README.md" <<'EOF'
# Demo Project
See [missing doc](docs/deleted-architecture.md) and [connected doc](docs/connected.md).
EOF
cat > "$tmp/docs/connected.md" <<'EOF'
# Connected Doc
EOF
cat > "$tmp/docs/orphan.md" <<'EOF'
# Orphan Doc Nobody Links To
EOF
cat > "$tmp/docs/decisions/0001-use-go.md" <<'EOF'
# 0001. Use Go for API
EOF

out_bad=$(bash "$here/doc_audit.sh" "$tmp")
echo "$out_bad" | grep -q "БИТАЯ ССЫЛКА: README.md -> docs/deleted-architecture.md" && ok "doc_audit.sh catches broken link" || bad "doc_audit.sh missed broken link"
echo "$out_bad" | grep -q "СИРОТА (нет входящих ссылок): docs/orphan.md" && ok "doc_audit.sh catches orphan doc" || bad "doc_audit.sh missed orphan doc"

out_map=$(bash "$here/doc_map.sh" "$tmp")
echo "$out_map" | grep -q 'cmd/api' && echo "$out_map" | grep -q '0001. Use Go for API' && ok "doc_map.sh discovers Go module, docs, and ADR" || bad "doc_map.sh failed to map project"

[ "$fail" = 0 ] && echo "ALL OK" || exit 1
