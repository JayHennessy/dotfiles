# User Guidelines

## Commits

- **Never include `Co-Authored-By` lines in commit messages.** No Claude co-authorship attribution.

## Plans, Specs, and Docs

- **All plans, specs, and documentation should be saved in a repo-specific folder within `~/.claude/`.**
  For example, for a project at `~/myproject`, use `~/.claude/myproject/` to store plans, specs, and docs.

## Worktrees

- **Git worktrees should be created in `~/.worktrees/<repo>/<branch-name>/`.**

## Continuous Improvement Suggestions

- **Proactively suggest workflow improvements when you notice friction or repetition during sessions.**
  When something is repeated across a session (or clearly recurs across sessions), flag it and propose the right automation:
  - Repeated multi-step task or procedure → suggest a **skill**
  - Repeated correction, preference, or instruction I have to give you → suggest a **CLAUDE.md rule**
  - Something that should happen automatically on an event (after edits, before commits, etc.) → suggest a **hook**
  - Repeated permission prompts for the same safe commands → suggest a **permissions allowlist entry**
- Make the suggestion brief and concrete (what to add, where, and why), ideally at a natural pause or end of the task — don't interrupt mid-flow. Only suggest when the value is real; skip one-offs.
- **When I correct your approach, tool choice, or style, persist it to your memory immediately** as feedback (what was wrong, why, how to apply next time) so the same correction never has to be given twice.
- **Also append every workflow-improvement suggestion to `~/.claude/improvements.md`** (create if missing) with the date and a one-line rationale, so suggestions survive the session. A weekly retro job consumes this inbox — remove entries once implemented.
