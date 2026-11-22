# Six Finding Classes — Symptoms, Cost, Detection, Remedy

## 1. Stale (Протухшее)
- **Symptom:** Doc describes a path, CLI flag, API, default value, or version that code has since changed.
- **Cost:** Worse than no doc—it lies confidently and misleads humans and agents.
- **Detection:** `rg` literal file/function names from the doc; test commands; compare `git log` dates of the doc vs the code module listed in `> **Code:** path/to/pkg` (`doc_audit.sh` Section 4).
- **Remedy:** Update the fact in place if the doc is still relevant; if the entire doc was superseded, move to Abandoned and delete/archive.

## 2. Abandoned (Брошенное)
- **Symptom:** The entire subject of the document (module, service, feature flag, workflow) was deleted from code.
- **Cost:** Wastes reader and agent tokens planning around non-existent architecture.
- **Detection:** `git log --follow` on the deleted module; zero occurrences in the source tree.
- **Remedy:** Delete from the working tree (git history preserves it, note in `docs/README.md` under "History") or mark explicitly as historical ADR. Ask the owner before deleting recent or externally linked docs.

## 3. Duplicated (Задвоенное)
- **Symptom:** The same rule, command, or number is restated in 2+ files in different words (e.g., separate hand-edited `CLAUDE.md` and `AGENTS.md`, or README vs `docs/`).
- **Cost:** Inevitably diverges when one copy is updated and the other is forgotten.
- **Detection:** Compare overlapping docs (`AGENTS.md` vs `CLAUDE.md`, `README.md` vs `docs/deploy.md`).
- **Remedy:** Pick one canonical home (closest to the code) and replace duplicates with a 1-line link (*Route, Don't Replicate*). Make `CLAUDE.md` a symlink to `AGENTS.md`.

## 4. Missing (Недостающее)
- **Symptom:** Project conventions require a doc or ADR (e.g., new service, major architectural decision, production runbook), or `doc_map.sh` shows a core code module with no linked doc in `docs/README.md`.
- **Cost:** Decisions without an ADR get accidentally reversed by future sessions (`honesty.md` rule 1).
- **Remedy:** Flag the missing doc/ADR to the owner and offer a draft from `templates/ADR-TEMPLATE.md`. Never fabricate rationale for a decision you didn't witness.

## 5. Bloated (Раздутое)
- **Symptom:** Factually accurate, but so long or unstructured (`AGENTS.md` >150 lines, doc >250 lines without headings/TOC, rare edge cases mixed into the happy path) that nobody reads it and agent context gets polluted.
- **Cost:** Bloated always-on instruction files degrade agent accuracy by 20–25% and burn tokens on every turn.
- **Remedy:** Extract topic details into `docs/<topic>.md`, keep `AGENTS.md` as a compact routing table, add a TOC, and delete facts trivially readable from type signatures.

## 6. Orphan / Unlinked (Несвязанное / Сироты)
- **Symptom:** A `.md` file sits in `docs/` with zero inbound links from `docs/README.md` or `AGENTS.md`, or lacks a `> **Code:**` header tying it to code modules.
- **Cost:** Agents traversing from the repo root never discover the file, leading to duplicate docs or broken invariants.
- **Detection:** Run `bash scripts/doc_audit.sh <root>` (Section 3 computes the markdown link graph and lists zero-indegree nodes).
- **Remedy:** Connect every live doc into `docs/README.md` (`templates/DOCS-MOC.md`) with its code module and ADR links, and archive dead audit dumps.
