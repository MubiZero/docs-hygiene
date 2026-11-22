# Protocol: Audit, Evidence, and Repair

## Modes
- **Audit (Default, Read-Only):** Triggered by "доки протухли", "аудит доков", "проверь документацию". Modify nothing in the repository; output the report with concrete evidence.
- **Repair & Map Building:** Triggered only after the report and explicit owner confirmation ("почисти", "собери карту", "исправь протухшее"). Fix one class per commit/PR. Do not bundle stylistic rewrites (Class 5) into factual fixes (Class 1/3/6).

## Evidence Over Intuition
- **Stale (Class 1):** Quote the doc + show actual code/command state + verification method (`rg`, command output, `git log` commit date).
- **Abandoned (Class 2):** Cite the deletion commit from `git log` or prove absence in the tree.
- **Duplicated (Class 3):** Quote both files side-by-side and state whether they already contradict each other or only risk future drift.
- **Orphan (Class 6):** Output from `doc_audit.sh` showing zero inbound links from entrypoints.

## Suggest-First & Protected Files
- Broken links, non-existent file paths, and symlinking `CLAUDE.md -> AGENTS.md` can be applied directly once repair mode is approved. Content rewrites require showing the proposed diff/text first unless the owner asked for a batch cleanup.
- **Never edit protected files:** auto-generated CHANGELOGs, OpenAPI/proto outputs (fix the generator source), `LICENSE`, or files marked `DO NOT EDIT`.
