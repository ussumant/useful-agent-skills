# codex-dispatch

Stop losing Codex CLI runs to timeouts, oversized diffs, and duplicate reviews.

## Problem

Calling the OpenAI Codex CLI directly has three ways to waste a run:

- **Foreground timeouts.** Agent harnesses that shell out via a "Bash tool"
  commonly hard-cap a foreground call at a fixed wall-clock limit (often
  around 10 minutes) and kill the whole process tree when it hits. A long
  `codex review` running in the foreground is how you lose the run *and*
  the tokens it already spent, with no partial output.
- **Oversized diffs.** A review-shaped prompt against a huge, unrelated-commits
  diff burns tokens and buries the real findings in noise.
- **Duplicate spend.** Nothing stops an agent from firing "review this"
  at the same unreviewed-since-last-time commit five times in one session.

## What it does

`dispatch.sh` wraps the `codex` binary with:

- **Auth gate** — a free `codex login status` check before anything dispatches.
- **Diff-size cap** — review-shaped dispatches get checked against a
  changed-line cap before they're sent; over cap is refused (with an override).
- **One-review-per-push dedup** — refuses to re-review a SHA you already reviewed.
- **Detach mechanics** — `dispatch.sh detach` runs a command in its own OS
  session so a harness timeout or restart can't kill it mid-run.
- **A ledger** — every dispatch, gated or not, is logged with timestamp,
  cwd, model, effort, and exit status.

## Before / after

The same "review this PR with codex" request. Both images are renderings of
a real terminal session in the skill's actual output format, with example
numbers (repo name, line counts, PIDs) standing in for a real run.
Transcripts in [`examples/`](examples/).

Before: the review runs in the foreground with no gates. It's still working
through a 4,200-line diff when the 10-minute tool cap kills it — no output,
tokens already spent.

![before](examples/before.png)

After: the diff-size cap catches the oversized diff before anything is
spent. Once split under the cap, the run dispatches detached so the timeout
can't touch it. A second attempt at the same commit is refused by the
dedup gate instead of paying for the same review twice.

![after](examples/after.png)

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the codex-dispatch skill from https://github.com/ussumant/useful-agent-skills and wire it up per its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill codex-dispatch --global --yes
```

Requires the [Codex CLI](https://github.com/openai/codex) installed and
authenticated (`codex login`) — this skill gates dispatches, it doesn't
manage credentials.

## How to use

```bash
# review a diff (prompt via stdin — a large positional prompt can
# silently no-op on some CLI versions)
echo "Review the diff in this repo for correctness and safety" \
  | ./dispatch.sh run exec -C /path/to/repo -s read-only

# codex review passthrough
./dispatch.sh run review "focus on the auth changes" < /dev/null

# a long run that must survive a harness timeout/restart
./dispatch.sh detach /tmp/codex-run-results -- \
  bash -c 'echo "review this diff" | ./dispatch.sh run exec -C /path/to/repo -s read-only'
# poll /tmp/codex-run-results for a line matching ^rc=

# status, ledger, usage
./dispatch.sh status
./dispatch.sh ledger 20
./usage.sh --brief
```

`CODEX_DISPATCH_DRY_RUN=1` runs every gate and prints the resolved `codex`
argv instead of dispatching — use it to see what a call would send before
it spends anything.

| Env var | Default | Meaning |
|---|---|---|
| `CODEX_DISPATCH_MODEL` | unset | `-c model=` pin, if you want one |
| `CODEX_DISPATCH_EFFORT` | unset | `-c model_reasoning_effort=` pin, if you want one |
| `CODEX_DISPATCH_DIFF_CAP` | `1500` | changed-line cap for review-shaped dispatches |
| `CODEX_DISPATCH_BASE_REF` | auto | base ref for the diff cap (else `origin/HEAD` → `main` → `master`) |
| `CODEX_DISPATCH_DIFF_OVERRIDE` | unset | `1` bypasses the diff cap (logged) |
| `CODEX_DISPATCH_DEDUP_OVERRIDE` | unset | `1` bypasses the one-review-per-push gate (logged) |
| `CODEX_DISPATCH_NO_DEDUP` | unset | `1` disables the dedup gate entirely |
| `CODEX_DISPATCH_HOME` | `~/.codex-dispatch` | state dir (dedup record + ledger) |
| `CODEX_DISPATCH_LEDGER` | `<home>/ledger.log` | ledger file path |
| `CODEX_DISPATCH_DRY_RUN` | unset | `1` prints argv instead of dispatching |
| `CODEX_DISPATCH_SESSIONS_DIR` | `~/.codex/sessions` | where `usage.sh` reads codex's own session logs from |

## What's inside

- [`SKILL.md`](SKILL.md) — the dispatch form and gate rules your agent loads
- [`dispatch.sh`](dispatch.sh) — the wrapper: auth gate, diff-size gate,
  dedup gate, ledger, and the `detach` / `status` / `ledger` subcommands
- [`detach.py`](detach.py) — runs a command in its own OS session so a
  harness timeout or restart can't kill it mid-run
- [`usage.sh`](usage.sh) — reads codex's own per-session token-usage logs
  for a day (no network call)
- [`gates-selftest.sh`](gates-selftest.sh) — exercises every gate against a
  throwaway repo and a fake `codex` binary; run it with `bash gates-selftest.sh`

## Honest caveats

- Codex CLI flags, model names, and session-log formats change across
  versions. Confirm with `codex --help` / `codex exec --help` before
  pinning a model, and check `CODEX_DISPATCH_SESSIONS_DIR` if `usage.sh`
  reports no runs.
- The review-shaped detection (which triggers the diff-size and dedup
  gates) is a simple case-insensitive substring match on the first 300
  bytes of the prompt (`review|verdict|adversar`). It will occasionally
  over- or under-trigger on prompt wording — every gate it drives has a
  named, logged override.
- Every dispatch costs whatever account `codex` is authenticated against.
  This wrapper reduces wasted spend; it does not make dispatches free.
- `gates-selftest.sh` never calls a real Codex account — it stubs `codex`
  with a fake binary on `PATH` and sets `CODEX_DISPATCH_SKIP_AUTH=1`. Never
  set that variable outside a test.

## License

MIT
