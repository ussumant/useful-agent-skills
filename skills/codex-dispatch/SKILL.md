---
name: codex-dispatch
description: >-
  Gated dispatch lane for the OpenAI Codex CLI — a wrapper that checks
  auth/liveness before spending, caps review-shaped dispatches by diff size,
  refuses to re-review a SHA you already reviewed, detaches long runs so a
  10-minute foreground tool cap can't kill them, and ledgers every dispatch.
  Use for: "codex review", "dispatch to codex", "second opinion", "ask codex",
  "codex on this diff/PR", or setting up a cost-gated codex lane.
---

# Codex Dispatch

A lane switch, not a new workflow. `dispatch.sh` sits between you and the
bare `codex` binary and adds four things the CLI doesn't have on its own:
a pre-flight auth check, a diff-size cap, a one-review-per-push dedup gate,
and a ledger. The skill decides when to call it; the script enforces the
gates.

## Why a wrapper at all

Calling `codex` directly has three failure modes this wrapper exists to
catch:

1. **Spending on a dead seat.** Not logged in, or the CLI predates a
   feature you're relying on — you find out after the run, not before.
2. **Handing Codex a huge diff.** A review-shaped prompt against a
   thousands-of-lines diff burns tokens and buries the signal in noise.
3. **Re-reviewing the same commit.** Nothing stops you from firing five
   "review this" dispatches at one unchanged SHA across a chat session.

None of this is Codex-specific in spirit — the same shape (auth gate, size
cap, dedup, ledger) applies to any CLI-driven model dispatch you're paying
for per call.

## The dispatch form

```bash
# review a diff — prompt via stdin, not positional (positional can silently
# no-op on some CLI versions with large prompts)
echo "Review the diff in this repo for correctness and safety issues" \
  | ./dispatch.sh run exec -C /path/to/repo -s read-only

# codex review passthrough
./dispatch.sh run review "focus on the auth changes" < /dev/null

# check codex login status + recent dispatch ledger
./dispatch.sh status
```

Model and reasoning-effort are **not hardcoded**. Set `CODEX_DISPATCH_MODEL`
/ `CODEX_DISPATCH_EFFORT` if your plan wants a specific pin — otherwise the
wrapper leaves it to Codex's own defaults. Codex CLI flags and model names
change across versions; confirm with `codex --help` / `codex exec --help`
before pinning anything.

## The gates (`dispatch.sh run`)

Only "review-shaped" dispatches trigger the diff-size and dedup gates: an
explicit `codex review`, or an `exec` whose prompt reads as a
review/verdict/adversarial ask (case-insensitive substring match). Plain
build/consult prompts skip both.

1. **Auth gate** — `codex login status` (a free, local check) must succeed
   before anything dispatches. Fails fast with an actionable message
   instead of burning a run on a dead seat.
2. **Diff-size cap** — for review-shaped dispatches in a git repo, the
   changed-line count against a base ref (`CODEX_DISPATCH_BASE_REF`,
   auto-detected from `origin/HEAD` → `main` → `master` otherwise) is
   checked against `CODEX_DISPATCH_DIFF_CAP` (default 1500 lines).
   Over cap → refused (exit 3) with the number and the override:
   `CODEX_DISPATCH_DIFF_OVERRIDE=1`.
3. **One-review-per-push dedup** — the current SHA on the current
   repo+branch is checked against the last SHA reviewed on that key
   (`~/.codex-dispatch/last-reviewed-sha.tsv` by default). Same SHA again →
   refused (exit 3): push a new commit, or override with
   `CODEX_DISPATCH_DEDUP_OVERRIDE=1`.
4. **Ledger** — every dispatch (permitted or gate-refused) appends a line
   to `CODEX_DISPATCH_LEDGER` (default `~/.codex-dispatch/ledger.log`):
   timestamp, subcommand, cwd, model, effort, exit status.

Exit code 3 always means a gate refused the run — resolve it or use its
named override (which is logged, so it's visible after the fact).

`CODEX_DISPATCH_DRY_RUN=1` runs every gate but prints the resolved `codex`
argv instead of dispatching — use it to confirm what a call would actually
send before it spends anything.

## Detaching long runs

Agent harnesses that shell out via a "Bash tool" commonly hard-cap a
foreground call at a fixed wall-clock limit (often around 10 minutes) and
SIGTERM the whole process tree when it hits — a long `codex review` running
in the foreground is how you lose both the run and the tokens it already
spent. A harness restart/resume can also kill in-process children and plain
`nohup`'d background jobs.

```bash
./dispatch.sh detach /tmp/codex-run-results -- \
  bash -c 'echo "review this diff" | ./dispatch.sh run exec -C /path/to/repo -s read-only'
```

This runs the command in its own OS session (`start_new_session=True`), so
neither a timeout kill nor a harness restart reaches it. It logs to
`<RESULTS>.log` and writes `rc=<code>` to `<RESULTS>` on exit. Poll for that
marker with whatever polling primitive your harness gives you (a watch
loop, a scheduled check-in) — never `pgrep`, since the dispatched process's
name usually won't match your command string.

## Usage / cost visibility

```bash
./usage.sh              # today's token usage from codex's own session logs
./usage.sh 2026-01-15    # a specific day
./usage.sh --brief       # one-line summary only
./dispatch.sh ledger 20  # last 20 dispatches from this wrapper's own ledger
```

`usage.sh` reads Codex's own per-session JSONL logs (no network call, no
extra billing) — the location is a Codex CLI implementation detail;
override with `CODEX_DISPATCH_SESSIONS_DIR` if your install writes
elsewhere. `dispatch.sh ledger` is a different, wrapper-owned record: every
call this script made, gated or not.

## Honest caveats

- Requires the Codex CLI installed and authenticated (`codex login`) — this
  skill doesn't manage credentials, it gates around whatever's already
  configured.
- Codex CLI flags, model names, and session-log formats change across
  versions. The regexes and paths here match a recent CLI; if a dispatch
  behaves unexpectedly, check `codex --help` and the CLI's changelog before
  assuming the wrapper is wrong.
- The review-shaped detection is a simple case-insensitive substring match
  on the first 300 bytes of the prompt (`review|verdict|adversar`) — it
  will occasionally over- or under-trigger on prompt wording; the gates
  it drives are all overridable.
- Every dispatch costs the account it's authenticated against. This wrapper
  reduces wasted spend; it does not eliminate cost.
