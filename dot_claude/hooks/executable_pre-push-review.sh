#!/usr/bin/env bash
# PreToolUse hook on Bash(git push*): if the outgoing diff is large, inject a
# reminder into Claude's context to consider running /code-review before pushing.
# Never blocks — informational only.
set -uo pipefail

input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0

# Skip the dotfiles repo — changes there are small config edits.
case "$cwd" in
    "$HOME/dotfiles"|"$HOME/dotfiles"/*) exit 0 ;;
esac

threshold="${PUSH_REVIEW_THRESHOLD:-200}"

# Compare against the upstream of the current branch; nothing to say if none.
upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{u}' 2>/dev/null) || exit 0
lines=$(git -C "$cwd" diff --numstat "$upstream"...HEAD 2>/dev/null | awk '{s+=$1+$2} END {print s+0}')

if [ "${lines:-0}" -gt "$threshold" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Pre-push check: ~%s changed lines are about to be pushed from %s. Consider running /code-review on this diff before pushing."}}\n' "$lines" "$cwd"
fi
exit 0
