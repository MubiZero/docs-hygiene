#!/usr/bin/env bash
# doc_audit.sh — быстрая разведка документации проекта для docs-hygiene:
# 1) Инвентаризация всех .md файлов (строки, дата последнего коммита, кандидаты на «раздутое» >250 строк без оглавления).
# 2) Проверка всех относительных ссылок [text](path) в .md файлах на существование (кандидаты на «протухшее» / «брошенное»).
# Usage: bash doc_audit.sh [project-dir]
set -euo pipefail

root="${1:-.}"
cd "$root"

echo "=== 1. Инвентаризация документов (.md) ==="
printf "%-50s %7s %12s %s\n" "ФАЙЛ" "СТРОК" "ПОСЛ.КОММИТ" "ЗАМЕТКА"
while IFS= read -r f; do
  f_clean="${f#./}"
  lines=$(wc -l < "$f" | tr -d ' ')
  last_date=$(git log -1 --format="%cs" -- "$f" 2>/dev/null || echo "untracked")
  note=""
  if [ "$lines" -gt 250 ]; then
    headers=$(grep -c '^##' "$f" 2>/dev/null || true)
    note="крупный (${headers} разделов ##)"
  fi
  printf "%-50s %7s %12s %s\n" "$f_clean" "$lines" "$last_date" "$note"
done < <(find . -name '*.md' \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/build/*' \
  -not -path '*/.dart_tool/*' \
  -not -path '*/vendor/*' | sort)

echo
echo "=== 2. Проверка относительных ссылок в .md ==="
broken=0
while IFS= read -r f; do
  d=$(dirname "$f")
  while IFS= read -r link; do
    target="${link%%#*}"
    [ -z "$target" ] && continue
    case "$target" in
      http://*|https://*|mailto:*|customization://*|plugin://*|conversation://*|file://*) continue ;;
    esac
    if [ ! -e "$d/$target" ] && [ ! -e "./$target" ]; then
      echo "  БИТАЯ ССЫЛКА: ${f#./} -> $link"
      broken=$((broken + 1))
    fi
  done < <(grep -oE '\]\([^) ]+\)' "$f" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' || true)
done < <(find . -name '*.md' \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/build/*' \
  -not -path '*/.dart_tool/*' \
  -not -path '*/vendor/*' | sort)

[ "$broken" -eq 0 ] && echo "  ✓ Все относительные ссылки ведут на существующие файлы"
