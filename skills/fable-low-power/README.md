# fable-low-power

Stop burning your frontier-model quota on grunt work.

## Problem

Anthropic usage limits are windowed: a 5-hour window and a 7-day window.
The frontier model you want for judgment spends most of its tokens on things
any cheaper model could do — file reads, greps, builds, test runs, draft
after draft. You find out mid-task, when the limit locks you out for hours
or until the week rolls over.

## What it does

- **Watches your live limits** — the signal is the JSON payload Claude Code
  already pipes into your statusline on every render tick. No credentials,
  no API calls, nothing phones home.
- **Flips into low power automatically** when the 5h/7d windows cross
  thresholds (manual `on`/`off` too): a session-start banner and mid-session
  notices arm a hard rail — the frontier model judges, plans, and issues
  verdicts ONLY; every execution step routes to subagents on cheaper models.
- **Tracks frontier burn per session** — cost, main-loop tokens, session
  count, today and trailing 7 days — so you can see whether the routing
  actually saves quota:

```text
🪫 FABLE LOW POWER MODE — ON. Limits: 5h 62% (resets Tue 23:00), 7d 78% (resets Mon 07:00).
📈 Frontier burn: today 3 frontier sessions · $41.20 · 12.3k tok out · 7d $209 · workers today $6.10
```

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the fable-low-power skill globally from https://github.com/ussumant/useful-agent-skills and wire it up per its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill fable-low-power --global --yes
```

Then wire the statusline and hooks in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/skills/fable-low-power/statusline-tee.sh"
  },
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "bash ~/.claude/skills/fable-low-power/low-power-mode.sh session-start" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "bash ~/.claude/skills/fable-low-power/low-power-mode.sh prompt" } ] }
    ]
  }
}
```

Already have a statusline script you like? Keep it — graft the block between
`TEE-START` and `TEE-END` in `statusline-tee.sh` into it. Everything else
reads the teed payload file, not your statusline. (Gotcha: the tee consumes
stdin — if your script reads stdin again later, read the teed file instead.)

Restart Claude Code. The state file `~/.claude/fable-low-power.json` is
created on first run.

## How to use

```text
/fable-low-power           → status: mode, 5h/7d %, resets, frontier burn
/fable-low-power on        → force low power now
/fable-low-power off       → back to normal routing
/fable-low-power auto      → let the thresholds decide (default)
```

Auto mode flips ON at 5h ≥ 60% or 7d ≥ 75%, and back OFF only below
5h 40% and 7d 65% — hysteresis, so it never flaps. Edit the thresholds
and the frontier-model matcher in `~/.claude/fable-low-power.json`:

| Key | Default | Meaning |
|---|---|---|
| `mode` | `auto` | `auto` = thresholds decide · `on`/`off` = manual override |
| `thresholds.on_5h` / `on_7d` | 60 / 75 | flip ON at these used-% |
| `thresholds.off_5h` / `off_7d` | 40 / 65 | flip back OFF only below BOTH |
| `model_match` | `"fable"` | substring marking a session as frontier (e.g. `"opus"`) |

## What's inside

- [`SKILL.md`](SKILL.md) — the low-power profile your agent loads: what the
  frontier model may spend tokens on, what must route to cheaper models
- [`limit-sense.sh`](limit-sense.sh) — the sensor: reads the teed payload,
  decides on/off with hysteresis, aggregates the burn ledger
- [`statusline-tee.sh`](statusline-tee.sh) — minimal statusline that tees the
  payload and writes the per-session usage ledger
- [`low-power-mode.sh`](low-power-mode.sh) — SessionStart/UserPromptSubmit
  hook that announces the mode and mid-session flips

## Honest caveats

- Per-session `cost_usd` includes in-session subagents; `out_tokens` is the
  main loop only — the truest "frontier model itself" number.
- Headless `claude -p` runs never render a statusline, so they don't appear
  in the ledger.
- The payload format is an implementation detail of Claude Code's statusline
  contract; if a future version renames fields, the sensor degrades to
  "holding last state" rather than breaking your session (it always exits 0).

## License

MIT
