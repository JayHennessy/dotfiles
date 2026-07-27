---
name: remote-exec
description: Run commands on Jay's remote work envs (calgary, kflow, uhn-gcp) from a local Claude session using the rex CLI. Use whenever a command, script, build, or check needs to run on a remote machine/pod — "run this on calgary", "check the kflow pod", "on the uhn pod...", "remotely". Also covers remote auth/VPN recovery and file transfer.
---

# Remote execution via rex

All remote work runs from the local machine with `~/altis/rex/rex`. Never tell the user to ssh somewhere manually; run it for them.

## Environments

| env | what | repo root | transport |
|---|---|---|---|
| calgary | UofC worker (ssh UoC-worker) | /home/jay.hennessy | ssh, key auth — **needs UoC VPN** |
| kflow | EKS notebook pod jay-vscode-0, ns kubeflow-jay | /home/jovyan/shared/users/jhennessy | aws-vault platform-engineer-kflow + kubectl |
| uhn-gcp | GKE pod pipeline-operator-shell-\<gcloud-user\>, ns ray-dev | /workspace | kubectl (gcloud auth), container `shell` |

All three have the repos: dicom-crawler, clinical-db, ml-serve.

**Client envs — production, dev, jnj, merck, bayer, pfizer, uhn-aws, hhs, genentech, bccancer, uofc — all connect through kflow.** Use them directly as the rex env: `rex run jnj 'aws sts get-caller-identity'` runs on the kflow pod with `AWS_PROFILE=jnj-reader` (IRSA; same profiles as ml-serve's `just assume` and clinical-db's `just env`). Role: `--as reader|writer|admin`, default reader — use the least privileged role that does the job. uhn-aws → profile prefix `uhn`.

## Commands

```bash
rex status <env>                                  # check ONLY the env you're about to use
rex run <env> [--repo <name> | --dir <path>] [--as <role>] '<cmd>'   # sync, streams output
rex zellij <env> [--repo|--dir] [--name <pane>] '<cmd>' # long-running work → remote zellij session "1"
rex push <env> <local> <remote-path>
rex pull <env> <remote-path> <local>
rex auth [env]                                    # interactive — user must run this, not Claude
rex vpn [up|down|status]                          # UoC VPN (calgary prereq)
rex shell <env>                                   # interactive shell — user-only
rex envs                                          # mapping cheat sheet
```

The remote command is evaluated once on the remote (quote it; `$HOME` etc. expand remotely). Each env gets a preamble: PATH is pre-seeded; on kflow both bashrcs are sourced (real home + proxy home — conda/mise/brew/aqua all resolve; HOME itself is NOT overridden) and the default cwd is the proxy home.

## Remote output capture (validation runs)

Never rely on `tail -N` of raw stdout or `2>/dev/null` for runs whose output you must verify — startup/Polars warnings swamp tails and suppressed stderr hides tracebacks (cost 4 inconclusive HPC re-validations on 2026-07-16).

```bash
rex run <env> 'CMD > /tmp/rex-out.log 2>&1; echo EXIT=$?'
rex run <env> 'tail -50 /tmp/rex-out.log'     # or: rex pull <env> /tmp/rex-out.log ./
```

- Set `POLARS_SKIP_CPU_CHECK=1` on calgary to silence known-benign warnings.
- If a run pushes scratch files, verify they exist (`ls`) before re-running after any cleanup step — cleanup + silent re-run reports nothing.

## Per-env gotchas

- `rex push <env> <local> <remote-path>`: remote path resolves from the **pod home**, not the `--repo` root. `--repo clinical-db` + push to `clinical-db/...` double-prefixes. Use home-relative or /tmp paths.
- calgary: default python3 has no pyarrow — use the project venv (via `just`) or duckdb CLI for parquet.
- calgary: **DuckDB writes to a DB on `/work/altis` (NFS) SIGFPE** ("Floating point exception (core dumped)") mid-operation on large writes; reads over NFS are fine. To mutate a calgary DuckDB, `cp` it to local `/tmp`, run the write there, verify, then `cp`+`mv` the file back over the original. (Small metadata-only writes like `DROP TABLE` of empty tables are usually fine directly.) A negative PID in a "Conflicting lock is held in PID -N" error is the DuckDB-over-NFS stale-lock tell.
- calgary: importing the ingestion loader chain (`load_raw_*` → `read_data` → polars) in standalone python SIGILLs (CPU lacks polars' instructions; `POLARS_SKIP_CPU_CHECK` doesn't stop the crash). Read parquet directly with pandas in validation scripts.
- kflow: `just` works (pod and `~/shared/users/jhennessy/bin/just` are both x86_64; `just env <env> <role> -c '<cmd>'` runs fine non-interactively). An older note here claimed a wrong-arch binary — verified false 2026-07-27; check with `uname -m` + `just --version` before believing any arch claim.
- **RDS Postgres via `psql` (client envs): go through `just env`.** `just env <env> <role>` mints the DSN with `--encode`, so `psql "$CLINICAL_DB_DSN" -f x.sql` parses. Building one yourself outside an env shell (`get_pipeline_db_dsn.py dsn <env> <role>` with no `--encode`) fails `invalid URI query parameter: "Action"` — the raw IAM token contains `?`/`&`. Without `just env`, split the encoded DSN into fields (`scripts/pipeline_db_env_from_dsn.py`) and pass `-h/-p/-U/-d`; also export `PGSSLMODE=require` (RDS IAM refuses non-TLS: the tell is `server closed the connection unexpectedly`, while an unauthenticated-but-TLS attempt reaches `fe_sendauth: no password supplied`). `scripts/get_pipeline_db_dsn.py exec -- <cmd>` takes **no** env/role args — it reads `CLINICAL_DB_TYPE=aws` + `CLINICAL_DB_PG_*` from the environment; passing them (`exec dev writer -- …`) makes it `execvp("dev")`.

## Rules

- **Touch only the env the task needs.** Every rex command targets one env — never probe the others "just in case". Bare `rex status` (all three envs, three auth paths) is for when the user explicitly asks for overall health; otherwise use `rex status <env>` or just run the actual command and handle failure.
- **Sync vs zellij**: commands finishing in < ~2 min → `rex run`. Anything long (pipelines, batch jobs, builds) → `rex zellij` so it survives disconnects and the user can watch. Default session: "1" ("s1" on kflow) — rex picks the right one. Name panes meaningfully (`--name dat312-backfill`).
- Check on a zellij job: `rex run <env> 'zellij --session <1|s1> action dump-screen /tmp/d; tail -30 /tmp/d'` (dumps focused pane), or have the job tee to a log file and tail that.
- Zellij job scripts are left at `/tmp/rex-job-*.sh` on the remote for debugging.
- **Auth/VPN failures**: rex is non-interactive from Claude — do NOT retry on these; tell the user to run the fix in this session, then continue:
  - calgary "VPN is down" → `! ~/altis/rex/rex auth calgary` (starts openfortivpn-uoc.sh, SAML MFA in browser)
  - kflow aws-vault/MFA error → `! ~/altis/rex/rex auth kflow`
  - uhn-gcp gcloud token error → `! ~/altis/rex/rex auth uhn-gcp`
- **uhn-gcp pod may not exist** (created per-session via `ml-serve/scripts/uhn-gcp-pipeline-operator-pod.sh ray-dev`). `rex status` says so. Pod home is ephemeral — only /workspace survives recreation, so don't leave anything precious outside /workspace.
- Memory sync from these envs: `~/.claude/altis/pull-memories.sh` (separate tool).
- Full usage doc: `~/altis/rex/README.md`.
