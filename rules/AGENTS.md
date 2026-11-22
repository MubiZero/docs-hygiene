# Continuous Documentation Hygiene (Route, Don't Replicate)

1. **Router, not a wall of text:** root `AGENTS.md` (≤150 lines) holds build/test commands and a routing table (`Topic → File in docs/`); `CLAUDE.md` is a symlink to `AGENTS.md`.
2. **Map of Content (MOC):** hub `docs/README.md` links `Code Module ↔ Document ↔ Decision (ADR)`. Never leave orphan files in `docs/` without an inbound link from the hub and a header `> **Code:** path/to/module`.
3. **Code edit = synchronous doc edit** (`docs/api.md`, `docs/deploy.md`, `docs/status.md`, `AGENTS.md`) in the same commit. One fact lives in one place.
