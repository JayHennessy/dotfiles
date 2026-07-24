#!/usr/bin/env bash
# Weekly workflow retrospective — run headless by the claude-retro systemd user
# timer (Fridays 1:20am). Mines the improvement inbox + claude-mem observations
# and writes a proposals report. Read-only: it never modifies repos or config.
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

outdir="$HOME/.claude/dotfiles"
mkdir -p "$outdir"
report="$outdir/retro-$(date +%F).md"

prompt=$(cat <<'EOF'
You are running a weekly workflow retrospective for Jay's Claude Code setup.

Sources (skip gracefully if one is unavailable, but note it):
1. ~/.claude/improvements.md — inbox of deferred improvement suggestions
2. claude-mem observations from the past 7 days (mem-search / claude-mem MCP tools)
3. Recent dotfiles activity: git -C ~/dotfiles log --oneline --since='7 days ago'

Identify recurring friction:
- Repeated multi-step procedures -> skill candidates
- Repeated corrections or re-stated preferences -> CLAUDE.md rule candidates
- "After X, always Y" event patterns -> hook candidates
- Repeated permission prompts for safe commands -> allowlist entries

Output a markdown report (this is your final message, it is saved to a file):
# Weekly Workflow Retro — <date>
## Summary
## Findings
| friction | evidence | proposal | where it lives |
## Proposed changes
Concrete diffs or file sketches for each proposal worth doing.
## Inbox items processed
Which improvements.md entries this report covers.

Do NOT modify any files or repositories — this is a report only. Skip
one-off events; only propose changes with recurring value.
EOF
)

timeout 15m claude -p "$prompt" \
    --allowedTools "Bash(git log*)" "Bash(git diff*)" "mcp__plugin_claude-mem_mcp-search" \
    > "$report" 2>&1 || echo "(retro run failed or timed out, partial output above)" >> "$report"

echo "Retro written to $report"
