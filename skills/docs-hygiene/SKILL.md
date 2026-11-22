---
name: docs-hygiene
description: >-
  Audits project docs (README, docs/, AGENTS.md, CLAUDE.md, ADR) against real code and builds a Map of Content
  (Code Module ↔ Doc ↔ ADR). Catches 6 classes: stale, abandoned, duplicated, missing, bloated, and orphan docs.
  Use on: "доки протухли", "аудит доков", "почисти документацию", "составь карту проекта / доков", "опись проекта",
  docs audit, project map, map of content, documentation drift.
---

# docs-hygiene 2.0: Knowledge Graph & Trustworthy Docs

Docs rot for three reasons: code moves ahead of the doc, one fact is duplicated across three files, or docs sit as disconnected orphans with no inbound links from entrypoints (`AGENTS.md` or hub `docs/README.md`).

This plugin operates in two modes:
1. **Continuous hygiene (always active via plugin `rules/AGENTS.md`):** *Route, Don't Replicate* (`AGENTS.md` ≤150 lines as a routing table, `CLAUDE.md -> AGENTS.md` symlink, `docs/README.md` as Map of Content, synchronous doc updates in the same commit as code changes, zero orphan docs). See [references/blueprint.md](references/blueprint.md) and [templates/](templates/).
2. **Audit & Map of Content builder (on skill activation):** detects 6 defect classes and maps `Code Module ↔ Document ↔ Decision (ADR)`.

## Six Finding Classes

Full details and remedies: [references/classes.md](references/classes.md).

| # | Class | Question |
|---|---|---|
| 1 | **Stale (Протухшее)** | Did code change while the sentence about it stayed behind (or `Code:` tag paths are newer than the doc)? |
| 2 | **Abandoned (Брошенное)** | Does the document describe a module, feature, or flow that no longer exists in code? |
| 3 | **Duplicated (Задвоенное)** | Is the same fact restated in 2+ places (including diverging `CLAUDE.md` and `AGENTS.md`)? |
| 4 | **Missing (Недостающее)** | Does a module or architectural choice lack a required doc or ADR per project conventions? |
| 5 | **Bloated (Раздутое)** | Is the doc accurate but too long/unstructured (`AGENTS.md` >150 lines, doc >250 lines without TOC)? |
| 6 | **Orphan / Unlinked (Сироты)** | Does a file in `docs/` have zero inbound links from `docs/README.md` or `AGENTS.md`, or is the MOC hub missing? |

## Workflow

1. **Automated Recon & Graph Slice.** Run both helper scripts on the project root:
   - `bash <skill>/scripts/doc_audit.sh <project-root>` — inventory, broken links, orphan docs, `AGENTS.md`/`CLAUDE.md` divergence, and `Code newer than doc` drift (via `**Code:**` / `**Код:**` header tags).
   - `bash <skill>/scripts/doc_map.sh <project-root>` — discovers Go/Flutter code modules, docs, and ADRs to build `docs/README.md` (Map of Content).
2. **Verify Claims Against Code.** Check paths, commands, versions, and dates. Unverifiable claims are candidates for Bloated or Stale.
3. **Audit First, Never Edit Silently.** Output the report in Russian using the format below ([references/protocol.md](references/protocol.md)).
4. **Fix & Map by Class on Command.** Once approved by the owner:
   - Build or update hub `docs/README.md` from [templates/DOCS-MOC.md](templates/DOCS-MOC.md);
   - Trim root `AGENTS.md` into a routing table via [templates/AGENTS-TEMPLATE.md](templates/AGENTS-TEMPLATE.md) (and symlink `CLAUDE.md -> AGENTS.md`);
   - Add [templates/STATUS-TEMPLATE.md](templates/STATUS-TEMPLATE.md) and [templates/ADR-TEMPLATE.md](templates/ADR-TEMPLATE.md) as needed.

## Report Format (Reply to Owner in Russian)

```
**Документы:** <checked truth sources>.
**Протухшее:** N. <Doc claim> → <actual code state, with commit/date>.
**Брошенное:** N. <Doc> describes <X>, removed in <commit/date>.
**Задвоено:** N. <Fact> lives in <file A> and <file B> (diverges on <what>).
**Недостающее:** N. <Module/decision> missing required doc/ADR.
**Раздутое:** N. <Doc>, <M> lines that can be trimmed/routed.
**Несвязанное (Сироты и карта):** N. <Orphan doc without inbound link from docs/README.md or missing MOC hub>.
**Что чисто:** <briefly what is accurate and well-linked>.
**Рекомендация:** priority order to fix (usually Duplicated, Stale, and Orphans first; Bloated last).
```

## Boundaries

- **Read-only by default.** An audit request ends with the report; wait for explicit owner approval before editing.
- **Protected files.** Never touch licenses, external-format files, or generated changelogs/API specs (fix the generator source instead).
- **Intentional brevity is not a defect.** A short README pointing to `docs/README.md` is healthy routing.
- **Runway integration:** satisfies `runway` gate G11 (pilot documentation).
- **Project memory drift:** if stale repo docs match stale agent memory, suggest running `consolidate-memory`.
