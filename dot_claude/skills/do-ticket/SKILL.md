---
name: do-ticket
description: "Take a Linear ticket end-to-end: evaluate scope, plan with self-critique, implement with TDD in a worktree, and push a PR. Use whenever the user invokes /do-ticket, pastes a Linear ticket ID or URL and wants it done — 'work on ALT-123', 'pick up this ticket', 'implement this issue', 'do this ticket', 'knock out this issue' — or asks to execute, complete, or build a ticketed piece of work, even if they never say the word 'ticket'."
---

# Do Ticket

Take a Linear ticket from ID to pushed PR, autonomously. The user is delegating the whole
loop — evaluation, planning, implementation, review, PR — so don't check in at each phase.
Ask a question only when genuinely stuck: when the ticket, its comments, and the codebase
together cannot answer something that materially changes direction. Batch such questions
into one message rather than dribbling them out.

## Input

`/do-ticket <ticket-id-or-url>` — a Linear issue ID (e.g. `ALT-123`) or URL.
If no ticket is given, ask for one.

Run from the repository the ticket's work belongs to. If the current directory clearly
isn't that repo (ticket references code that doesn't exist here), say so and stop rather
than guessing — a PR against the wrong repo wastes everyone's time.

## Phase 1 — Fetch and understand

1. Fetch the issue via Linear MCP (`get_issue`): title, description, labels, estimate,
   parent/children, and the suggested git branch name.
2. Fetch its comments (`list_comments`) — decisions and constraints often live there,
   not in the description.
3. Locate the affected code. Read enough of it to understand the current behavior the
   ticket wants changed.

## Phase 2 — Evaluate scope

Estimate the ticket against this scale (same one `/ticket` uses):

| Points | Meaning |
|--------|---------|
| 1 | Trivial — clear what to do, no unknowns |
| 2 | Small — straightforward, minor unknowns |
| 3 | Medium — well-understood but meaningful scope |
| 5 | Large — multiple moving parts or moderate unknowns |
| 8 | Very large — significant unknowns or cross-cutting |
| 13 | Epic-sized — must be broken down |

If `docs/estimation.md` exists in the repo, apply its calibration notes.

**Split when 8+.** A ticket that big produces an unreviewable PR. Break it into
sub-issues that each ship independently, create them in Linear as children of the
original (team key from `.linear.yaml` in the repo root), comment on the parent
explaining the split, then work the **first** sub-issue through the rest of this
skill. Tell the user at the end which sub-issues remain.

## Phase 3 — Socratic pass

Before planning, interrogate the ticket the way a thoughtful reviewer would interrogate
you. Write out the questions someone would ask before starting — about intent, edge
cases, backwards compatibility, data migration, error handling, who consumes this — and
answer each one from the ticket, its comments, or the codebase.

- Answerable → note the answer; it feeds the plan.
- Unanswerable but immaterial → pick a sensible default and record the choice (it goes
  in the Linear comment and PR description, so the decision is visible and reversible).
- Unanswerable and direction-changing → this is the "genuinely stuck" case; ask the user.

The point is to surface wrong assumptions before they're load-bearing, not to produce
a document.

## Phase 4 — Plan, then attack the plan

Draft a plan: approach, files to touch, test strategy, risks, what's explicitly out of
scope.

Then spawn a contrarian subagent to grill it. Its brief: assume the plan is wrong and
find out how — hidden assumptions, missed edge cases, a simpler approach, scope creep,
interactions with code the plan didn't mention. Revise the plan with what survives
scrutiny. One hard critique pass is usually enough; a plan that still feels shaky after
revision is a signal the problem is under-specified — consider the superpowers plugin's
brainstorming/planning skills before pushing forward on sand.

Post a short comment on the Linear ticket summarizing the plan and any non-obvious
decisions from the socratic pass. This is the paper trail teammates see.

## Phase 5 — Worktree

Never work on a checkout someone might be using. Create a worktree:

- Branch name: Linear's suggested branch name if the issue provides one, else
  `jay/<ticket-id-lowercase>-<short-slug>`.
- Location: `~/.worktrees/<repo>/<branch-name>/` (user convention).

```bash
git worktree add ~/.worktrees/<repo>/<branch> -b <branch>
```

Do all remaining work inside the worktree.

## Phase 6 — Implement with TDD

Write the failing test first, then the code that makes it pass, then repeat. The tests
encode the acceptance criteria *before* the implementation biases what "correct" means —
that's the reason for the discipline, especially in an autonomous run where no human is
watching for drift.

- Follow the repo's conventions: README, CLAUDE.md, existing patterns, lint/format/test
  commands.
- Commit in coherent checkpoints with conventional-commit messages.
- **Secrets never enter the diff.** Before every commit, scan the staged changes for
  keys, tokens, passwords, connection strings. If the work needs a credential, wire it
  through env vars or the repo's existing secrets machinery and document that in the PR.

## Phase 7 — Quality gates

Run these once the implementation is green, in this order (cheap and behavior-changing
first, review last so it sees final code):

1. Repo's own lint, format, and full test suite.
2. `/simplify` on the diff — remove what the first draft over-built.
3. `/code-review` — fix real findings, note disputed ones for the PR.
4. Security review of the diff: injection, authz gaps, unsafe deps, and a final secrets
   sweep. Use `/security-review` if the change touches anything security-adjacent.

Where review effort is significant, prefer spawning independent reviewer subagents over
self-review — fresh context catches what the author cannot.

## Phase 8 — PR via /prepare

1. Make sure the worktree is clean — everything intentional is committed, nothing else.
2. Invoke the `/prepare` skill. It runs pre-PR checks, reviews the branch, assesses
   risk, creates the PR, and posts the review comment. Don't duplicate its work.
3. Update Linear: comment with the PR link plus a summary of decisions and anything
   discovered that changes how teammates should think about the area. Move the issue
   to "In Review" (or the team's equivalent) if the workflow has such a state.

## Phase 9 — Copilot review loop

Some repos (e.g. clinical-db) auto-trigger a GitHub Copilot review on PR creation.

1. Check for it: `gh pr view --json reviews,comments` shortly after creation.
2. If a Copilot review is pending or expected, poll every couple of minutes, up to
   ~15 minutes total.
3. Respond to every Copilot comment: either fix it (commit + reply noting the fix) or
   reply explaining why it doesn't apply. Unanswered bot comments make reviewers
   re-litigate them.
4. If the repo has no auto-review, skip this phase — don't wait on something that
   isn't coming.

## Phase 10 — Wrap up

Report to the user in one message:

- PR link and risk tier from `/prepare`
- Linear ticket link and its new status
- Sub-issues created and still open (if the ticket was split)
- Decisions made on their behalf that they may want to veto
- Anything blocked or needing human action

If the run surfaced friction worth capturing (missing docs, flaky tests, tooling gaps),
suggest `/retro`.

## Failure handling

- Blocked on access (auth, VPN, missing permissions) → state exactly what's blocking
  and stop; don't work around access controls.
- Ticket is already done, invalid, or duplicates existing work → comment that on the
  Linear issue, tell the user, stop.
- Tests can't pass for reasons outside the ticket's scope (pre-existing breakage) →
  note it in the PR and the ticket rather than silently expanding scope to fix it.
