---
name: retro
description: Use when the user invokes /retro or asks for a session retrospective — reviews the current session for friction and proposes skills, CLAUDE.md rules, hooks, or permission allowlist entries.
---

# Session Retro

Review the current conversation from the beginning and identify friction:

1. **Repeated commands/procedures** — same multi-step sequence run 2+ times → skill candidate
2. **Corrections** — user had to redirect approach, tool choice, or style → CLAUDE.md rule and/or persisted feedback memory
3. **Event-shaped work** — "after X, always Y" patterns → hook candidate
4. **Permission prompts** — repeated prompts for the same safe commands → permissions allowlist entry
5. **Failures** — commands or approaches that failed, and what fixed them → note the fix so it isn't rediscovered

## Output

A short markdown table: `friction | proposal | where it lives` (skill / CLAUDE.md / hook / permissions / memory). Skip one-offs — only propose things with real recurring value.

Then ask the user which proposals to implement.

## Implementation

- Config changes go through `~/dotfiles` (chezmoi source), applied with `chezmoi apply`, then committed and pushed per the dotfiles repo rules.
- Append any proposals the user defers (not rejected) to `~/.claude/improvements.md` with a date and one-line rationale, so the weekly retro can pick them up. Create the file if missing.
