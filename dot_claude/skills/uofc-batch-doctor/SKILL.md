---
name: uofc-batch-doctor
description: Use when a UofC/calgary SLURM batch or plan run looks frozen, stalled, or stuck, a cluster-up misbehaves, Ray actors seem dead, or the user says "batch doctor", "is the run stuck?", "check the cluster", "why is the batch not progressing".
---

# UofC batch doctor

One-shot triage of UofC SLURM batch runs, executed via rex against calgary. Run all probes, then report a **single verdict** with evidence: `RUNNING` / `STALLED` / `DEAD` / `CLUSTER-MISCONFIGURED`.

**REQUIRED SUB-SKILL:** remote-exec — all probes run through rex; capture each probe's output per its "Remote output capture" pattern (log to file, never suppress stderr).

## Probes (run all, in order)

| # | probe | command / check |
|---|---|---|
| 1 | Queue | `rex run calgary 'squeue -u jay.hennessy -o "%.10i %.20j %.8T %.10M %R"'` |
| 2 | Batch log | `rex run calgary 'ls -t slurm-*.out \| head -1 \| xargs tail -40'` |
| 3 | DB freshness | max(`last_modified`) on the batch DB head — stale >10 min = stalled |
| 4 | Ray liveness | actor/task state on the head node (`ray status` / `ray list actors`) |
| 5 | Head pin | compare `.head_node` / `head_host.txt` against the actual SLURM batch host |
| 6 | Node probes | hostname-verified ssh probe of each allocated node |

## Verdict

- **RUNNING** — job in queue, log advancing, DB fresh, Ray actors alive.
- **STALLED** — job alive but log/DB frozen >10 min or Ray tasks not progressing.
- **DEAD** — job gone from queue or Ray head unreachable.
- **CLUSTER-MISCONFIGURED** — head pin mismatch (`.head_node`/`head_host.txt` disagree with SLURM host) or node probes fail hostname verification.

State the verdict first, then the supporting evidence per probe.

## Rules

- **Read-only** — never cancel jobs, relaunch, or mutate cluster state; recommend the fix instead.
- calgary needs UoC VPN; on auth failure follow remote-exec's auth-recovery rule (ask Jay to run `! ~/altis/rex/rex auth calgary`, don't retry).
