# fable-low-power

Auto-detects when your Anthropic usage limits run low and flips Claude Code
into a token-saving profile: the frontier model (Fable/Opus) judges, plans,
and orchestrates ONLY — every execution step routes to subagents on cheaper
models. Also tracks your frontier-model burn per session, so you can see
whether the routing is actually saving quota.

No credentials, no API calls — the whole signal path is the JSON payload
Claude Code already pipes into your statusline on every render tick.

## What you get

- 🪫 A session-start banner when limits are low, with live 5h/7d percentages
  and reset times, plus mid-session flip notices at prompt boundaries
- 📈 A burn line: `today 2 frontier sessions · $4.98 · 12.3k tok out · 7d $31 · workers today $0.42`
- `/fable-low-power status|on|off|auto` — manual control with hysteresis
  thresholds you can edit in the state file

## Install

1. Copy the skill folder:

```bash
cp -r skills/fable-low-power ~/.claude/skills/fable-low-power
```

2. Wire the statusline and hooks in `~/.claude/settings.json`:

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

3. Restart Claude Code (or start a new session). The state file
   `~/.claude/fable-low-power.json` is created on first run.

## Config

Edit `~/.claude/fable-low-power.json`:

| Key | Default | Meaning |
|---|---|---|
| `mode` | `auto` | `auto` = thresholds decide · `on`/`off` = manual override |
| `thresholds.on_5h` / `on_7d` | 60 / 75 | flip ON at these used-% |
| `thresholds.off_5h` / `off_7d` | 40 / 65 | flip back OFF only below BOTH (hysteresis) |
| `model_match` | `"fable"` | substring marking a session as frontier (e.g. `"opus"`) |

## Honest caveats

- `cost_usd` per session includes in-session subagents; `out_tokens` is the
  main loop only — the truest "frontier model itself" number.
- Headless `claude -p` runs never render a statusline, so they don't appear
  in the ledger.
- The payload format is an implementation detail of Claude Code's statusline
  contract; if a future version renames fields, the sensor degrades to
  "holding last state" rather than breaking your session (it always exits 0).
