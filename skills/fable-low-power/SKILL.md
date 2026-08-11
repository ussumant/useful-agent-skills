---
name: fable-low-power
description: >-
  Fable Low Power mode — token-saving profile when Anthropic usage limits run
  low: the frontier model acts as decision maker, judge, and orchestrator ONLY;
  every execution step routes to cheaper models. Auto-armed by the limit-sense
  hook when the 5h/7d windows cross thresholds; also on demand. Use for:
  "low power", "save Fable", "limits are low", "running out of quota",
  "/fable-low-power", "conserve tokens", "battery mode".
---

# Fable Low Power Mode

A power profile, not a new orchestrator. This skill defines what CHANGES when
your Anthropic usage limits run low, and how the mode switches.

## State machine

State file: `~/.claude/fable-low-power.json` ·
Sensor: `~/.claude/skills/fable-low-power/limit-sense.sh`

- **Signal**: `rate_limits.five_hour/.seven_day.used_percentage` from the
  statusline payload Claude Code pipes per render tick, teed to
  `~/.claude/cache/statusline-payload.json` by `statusline-tee.sh`.
  No credentials involved. If you replace the statusline script, keep the tee.
- **Modes**: `auto` (default — thresholds decide) · `on` / `off` (manual, outranks auto).
- **Auto thresholds** (in the state file): ON when 5h ≥ 60% or 7d ≥ 75%;
  back OFF only when 5h < 40% and 7d < 65% (hysteresis, no flapping).
  Reading stale >30 min → hold last state.
- **Trigger**: `low-power-mode.sh` announces ON at session start and
  mid-session flips at prompt boundaries. Announcements instruct the session
  to invoke this skill.

## Subcommands (when invoked as /fable-low-power …)

| Args | Do |
|---|---|
| *(none)* / `status` | `bash ~/.claude/skills/fable-low-power/limit-sense.sh` → report effective state, mode, 5h/7d %, resets, thresholds, and frontier burn (`fable_today` / `fable_7d` / `workers_today`) — one screen. |
| `on` | `bash ~/.claude/skills/fable-low-power/limit-sense.sh set-mode on` → confirm, then APPLY the profile below immediately in this session. |
| `off` | `bash ~/.claude/skills/fable-low-power/limit-sense.sh set-mode off` → confirm normal routing resumed. |
| `auto` | `bash ~/.claude/skills/fable-low-power/limit-sense.sh set-mode auto` → report what auto currently decides. |

## Usage tracking

The statusline tee also writes a per-session ledger:
`~/.claude/cache/usage-sessions/<session_id>.json` — cumulative model, cost,
and main-loop token totals, atomically overwritten per tick (last write =
session totals). `limit-sense.sh` aggregates it into:

- `fable_today` — sessions whose main loop matches `model_match` (default
  `"fable"`, editable in the state file), active today: count, cost_usd,
  in/out tokens. `out_tokens` is the main loop only, so it's the closest
  proxy for "what the frontier model itself generated"; `cost_usd` includes
  in-session subagents.
- `fable_7d` — same over the trailing 7 days (matches the weekly limit window).
- `workers_today` — interactive sessions on other models. Headless `-p` runs
  never tick a statusline, so they don't appear.

The low-power banner surfaces this as "📈 Frontier burn: …". Ledger files
older than 8 days are pruned by the reader. Day attribution = a session's
last-active day (sessions spanning midnight count once, on the later day).

## The profile — what ON changes

ON hardens "the frontier model orchestrates, cheaper models execute" from
*default* to *hard rail*:

1. **The frontier model's token budget buys judgment only**: routing
   decisions, task specs, verdicts, taste calls, plans, and the reply to the
   user. Nothing else.
2. **No inline execution.** Searches, greps, probes, bulk file reads, builds,
   test runs, fixes, doc/deliverable drafting — ALL go to subagents on
   cheaper models (e.g. Sonnet for well-specified work, Haiku for scans).
   Agents return digests; bulk artifacts travel as file paths — the frontier
   model never pages through raw content it can have summarized.
3. **Supervision stays on**: task specs written junior-clear (exact paths,
   commands, expected output, "on ANY surprise stop and report"), and
   load-bearing claims spot-verified — via a cheap verify agent, not by the
   frontier model re-reading everything.
4. **One-screen replies, batched judgment.** Accumulate small rulings and
   deliver them together; one fix-worker per findings list, never one per
   finding; no long syntheses in chat — files.
5. **Park what doesn't need frontier judgment.** If a task needs no frontier
   call at all, dispatch it whole or park it with a one-line note.
6. **Floor, not theater**: if a dispatch would plainly cost more total tokens
   than a trivial inline action (a one-line edit, a `date`), do it inline.
   Low power saves tokens, not ceremony.

## Unchanged — these outrank the profile

- The quality bar never drops: if no affordable model clears a task's bar,
  stop and tell the user — never silently ship degraded work.
- Your project's own workflow rules (review gates, PR rituals, approval
  steps) keep their routing; this profile only governs everything else.
