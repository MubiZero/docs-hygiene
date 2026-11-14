# docs-hygiene

A [Claude Code](https://claude.com/claude-code) skill that audits a project's documentation
(README, `docs/`, `CLAUDE.md`, `AGENTS.md`, `decisions/`) against the actual code and memory:
what's stale, what's abandoned, what's duplicated across files until it drifts, what's missing
where the project's own convention requires it, and what's technically correct but too bloated
to read. Read-only by default — it reports with evidence (file:line, the commit that moved on
without the doc), and only edits on an explicit go-ahead, one class at a time.

Ask for it in plain words: *"are the docs still accurate?"*, *"clean up our docs"*, *"this
README is stale"*, *"почисти документацию"*, *"доки протухли"*.

## Install

```
/plugin marketplace add MubiZero/docs-hygiene
/plugin install docs-hygiene@docs-hygiene
```

## What it does

See [skills/docs-hygiene/SKILL.md](skills/docs-hygiene/SKILL.md) for the five finding classes
(stale, abandoned, duplicated, missing, bloated), the audit/fix protocol, and the evidence bar
each finding has to clear before it's reported.

## License

[MIT License](LICENSE) · Copyright (c) 2026 MubiZero
