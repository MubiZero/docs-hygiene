# Blueprint: Connected Documentation Graph (Obsidian-Style MOC)

The two classic documentation failures are **an unlinked dump of `.md` files** that agents never find, or **a 1,000-line `CLAUDE.md`** that pollutes context on every turn.

Follow **Route, Don't Replicate** using a four-layer directed graph:

```
AGENTS.md (root, ≤150 lines: commands + routing table "Topic → Doc", with CLAUDE.md symlinked to it)
   │
   ▼
docs/README.md (Hub / Map of Content: all live docs + "Code Module ↔ Doc ↔ ADR" matrix)
   ├──► docs/status.md (live project pulse: prod versions, store review status, open work, owner blockers)
   ├──► docs/<topic>.md (topic guide, header: "> **Code:** path/to/pkg · **ADR:** 0002")
   └──► docs/decisions/NNNN-slug.md (ADR: Status, Date, Scope, Code paths, Revisit trigger)
```

## Four Graph Invariants

1. **Zero Orphans:** Every file in `docs/*.md` has an inbound link from `docs/README.md` (or `AGENTS.md`), and every `docs/decisions/NNNN-*.md` is listed in `docs/decisions/README.md`.
2. **Explicit Code Binding (`Code:` / `Код:` header):** The first blockquote line after `# Title` names the code paths the document governs:
   `> **Code:** imon-api/internal/crm, docker/public-edge.conf.template`
   `doc_audit.sh` uses these paths to compare `git log` timestamps and flag when code moves ahead of its doc.
3. **Live vs History Separation:** One-off audits, completed migration plans, and role simulation logs are either removed from the working tree (referenced in `docs/README.md` under "History" via `git log --all -- <path>`) or clearly marked historical so agents never mistake an old audit for current state.
4. **Single Agent Entrypoint:** `AGENTS.md` is canonical; `CLAUDE.md` is a symlink (`ln -s AGENTS.md CLAUDE.md`).
