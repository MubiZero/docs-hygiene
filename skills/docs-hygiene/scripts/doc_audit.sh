#!/usr/bin/env bash
# doc_audit.sh — быстрая разведка документации и графа связей проекта для docs-hygiene 2.0:
# 1) Инвентаризация всех .md файлов (строки, дата последнего коммита, кандидаты на «раздутое» >250 строк).
# 2) Проверка всех относительных ссылок [text](path) в .md файлах на существование (кандидаты на «протухшее» / «брошенное»).
# 3) Поиск документов-сирот (Orphans: файлы в docs/, на которые нет входящих ссылок из README.md, AGENTS.md, CLAUDE.md, docs/README.md или других доков).
# 4) Проверка синхронности AGENTS.md и CLAUDE.md (если оба существуют и не симлинк/не идентичны).
# 5) Детектор дрейфа «Код новее привязанного дока» (по тегам `Код:` / `Затрагивает код:` в шапке документа).
#
# Usage: bash doc_audit.sh [project-dir]
set -euo pipefail

root="${1:-.}"
cd "$root"

python3 - <<'PY'
import os, re, subprocess, sys

EXCLUDE_DIRS = {".git", "node_modules", "build", ".dart_tool", "vendor", "dist"}

def git_date(path):
    try:
        out = subprocess.check_output(
            ["git", "log", "-1", "--format=%cs", "--", path],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        return out or "untracked"
    except Exception:
        return "untracked"

def git_ts(path):
    try:
        out = subprocess.check_output(
            ["git", "log", "-1", "--format=%ct", "--", path],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        return int(out) if out else 0
    except Exception:
        return 0

md_files = []
for dirpath, dirnames, filenames in os.walk("."):
    dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDE_DIRS)
    for fn in sorted(filenames):
        if fn.endswith(".md"):
            rel = os.path.normpath(os.path.join(dirpath, fn))
            md_files.append(rel)

print("=== 1. Инвентаризация документов (.md) ===")
print(f"{'ФАЙЛ':<50} {'СТРОК':>7} {'ПОСЛ.КОММИТ':>12} ЗАМЕТКА")

link_re = re.compile(r"\]\(([^) ]+)\)")
code_tag_re = re.compile(r"(?:\*\*Код:\*\*|\*\*Затрагивает код:\*\*|Затрагивает код:|Код:)\s*([^\n]+)")
backtick_re = re.compile(r"`([^`]+)`")

inbound = {f: set() for f in md_files}
broken_links = []
code_drift = []

for f in md_files:
    try:
        text = open(f, encoding="utf-8").read()
    except Exception:
        continue
    lines = text.count("\n") + (1 if text and not text.endswith("\n") else 0)
    dt = git_date(f)
    note = ""
    if lines > 250:
        h2 = len(re.findall(r"^##\s", text, re.MULTILINE))
        note = f"крупный ({h2} разделов ##)"
    elif f in ("AGENTS.md", "CLAUDE.md") and lines > 160:
        note = f"маршрутизатор >160 строк ({lines})"
    print(f"{f:<50} {lines:>7} {dt:>12} {note}")

    d = os.path.dirname(f) or "."
    is_template = "/templates/" in f or f.startswith("templates/")
    cleaned_for_links = re.sub(r"```.*?```|`[^`\n]+`", "", text, flags=re.DOTALL)
    for raw_link in ([] if is_template else link_re.findall(cleaned_for_links)):
        target = raw_link.split("#", 1)[0].strip()
        if not target or re.match(r"^(https?|mailto|customization|plugin|conversation|file)://", target):
            continue
        cand1 = os.path.normpath(os.path.join(d, target))
        cand2 = os.path.normpath(target)
        resolved = None
        if os.path.exists(cand1):
            resolved = cand1
        elif os.path.exists(cand2):
            resolved = cand2
        if resolved is None:
            broken_links.append((f, raw_link))
        else:
            if os.path.isdir(resolved):
                idx = os.path.normpath(os.path.join(resolved, "README.md"))
                if idx in inbound and idx != f:
                    inbound[idx].add(f)
            elif resolved in inbound and resolved != f:
                inbound[resolved].add(f)

    # Check code drift if doc declares "**Код:** `path/to/code`"
    m = code_tag_re.search(text[:1200])
    if m:
        doc_ts = git_ts(f)
        if doc_ts > 0:
            for cpath in backtick_re.findall(m.group(1)):
                cpath_norm = os.path.normpath(cpath.strip())
                if os.path.exists(cpath_norm) and cpath_norm != ".":
                    c_ts = git_ts(cpath_norm)
                    if c_ts > doc_ts:
                        code_drift.append((f, git_date(f), cpath_norm, git_date(cpath_norm)))

print("\n=== 2. Проверка относительных ссылок в .md ===")
if not broken_links:
    print("  ✓ Все относительные ссылки ведут на существующие файлы")
else:
    for src, lnk in broken_links:
        print(f"  БИТАЯ ССЫЛКА: {src} -> {lnk}")

print("\n=== 3. Граф связей и документы-сироты (Orphans) ===")
ROOT_ENTRYPOINTS = {"README.md", "AGENTS.md", "CLAUDE.md", "GEMINI.md", "docs/README.md", "SKILL.md", "rules/AGENTS.md"}
orphans = []
for f in md_files:
    if f in ROOT_ENTRYPOINTS or os.path.basename(f) == "SKILL.md" or f.startswith(("skills/", "rules/", ".agents/")):
        continue
    if not inbound.get(f):
        orphans.append(f)

if not orphans:
    print("  ✓ Сирот нет: все документы в docs/ связаны с точками входа")
else:
    for o in orphans:
        print(f"  СИРОТА (нет входящих ссылок): {o}")

if os.path.exists("AGENTS.md") and os.path.exists("CLAUDE.md"):
    if not (os.path.islink("AGENTS.md") or os.path.islink("CLAUDE.md")):
        a_txt = open("AGENTS.md", encoding="utf-8").read().strip()
        c_txt = open("CLAUDE.md", encoding="utf-8").read().strip()
        if a_txt != c_txt and len(a_txt) > 200 and len(c_txt) > 200:
            print("  РАСХОЖДЕНИЕ ИНСТРУКЦИЙ: AGENTS.md и CLAUDE.md — два разных файла (сделай CLAUDE.md симлинком на AGENTS.md)")

if code_drift:
    print("\n=== 4. Дрейф «Код новее документа» (Blast Radius) ===")
    for doc, d_dt, cpath, c_dt in code_drift:
        print(f"  КОД УЕХАЛ ВПЕРЁД: {doc} ({d_dt}) <- код {cpath} обновлён {c_dt}")
PY
