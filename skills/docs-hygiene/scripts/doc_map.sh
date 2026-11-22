#!/usr/bin/env bash
# doc_map.sh — строит карту связей проекта (Code Modules <-> Docs <-> ADRs) в формате Markdown,
# готовом для вставки в docs/README.md (Map of Content) или обзора перед аудитом.
# Usage: bash doc_map.sh [project-dir]
set -euo pipefail

root="${1:-.}"
cd "$root"

python3 - <<'PY'
import os, re, subprocess

EXCLUDE = {".git", "node_modules", "build", ".dart_tool", "vendor", "dist", ".claude-plugin", ".agents"}

def first_heading(path):
    try:
        for line in open(path, encoding="utf-8"):
            s = line.strip()
            if s.startswith("# "):
                return s[2:].strip()
    except Exception:
        pass
    return os.path.basename(path)

# 1. Discover code modules (Go cmd/internal/pkg, Flutter apps/packages, or top-level dirs with code)
modules = []
for dirpath, dirnames, filenames in os.walk("."):
    dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDE and not d.startswith("."))
    rel = os.path.normpath(dirpath)
    if rel == ".":
        continue
    if "go.mod" in filenames or "pubspec.yaml" in filenames or rel.startswith(("cmd/", "internal/", "pkg/", "apps/", "packages/")):
        depth = rel.count(os.sep)
        if depth <= 2:
            kind = "Go" if ("go.mod" in filenames or any(f.endswith(".go") for f in filenames)) else (
                "Flutter/Dart" if ("pubspec.yaml" in filenames or any(f.endswith(".dart") for f in filenames)) else "Module"
            )
            modules.append((rel, kind))

# 2. Discover docs and ADRs
docs = []
adrs = []
for dirpath, dirnames, filenames in os.walk("."):
    dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDE)
    for fn in sorted(filenames):
        if not fn.endswith(".md"):
            continue
        rel = os.path.normpath(os.path.join(dirpath, fn))
        if "decisions/" in rel and fn != "README.md":
            adrs.append((rel, first_heading(rel)))
        elif rel.startswith("docs/") or rel in ("README.md", "AGENTS.md", "CLAUDE.md"):
            docs.append((rel, first_heading(rel)))

print("# Карта проекта (Map of Content — автосрез)")
print("\n## 1. Модули кода")
if modules:
    print("| Путь модуля | Стек / Тип |")
    print("|---|---|")
    for m, k in modules[:25]:
        print(f"| `{m}` | {k} |")
else:
    print("_Модули Go/Flutter на верхних уровнях не обнаружены._")

print("\n## 2. Узлы документации")
if docs:
    print("| Документ | Заголовок / Назначение |")
    print("|---|---|")
    for d, h in docs:
        print(f"| [{d}]({d}) | {h} |")

if adrs:
    print("\n## 3. Архитектурные решения (ADR)")
    print("| Файл решения | Решение |")
    print("|---|---|")
    for a, h in adrs:
        print(f"| [{a}]({a}) | {h} |")
PY
