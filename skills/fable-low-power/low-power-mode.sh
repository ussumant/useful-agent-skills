#!/bin/bash
# low-power-mode.sh — Fable Low Power mode trigger hook.
# WIRE: SessionStart (arg: session-start) + UserPromptSubmit (arg: prompt)
#
# Reads limit-sense.sh (statusline-payload rate limits, no creds).
# Emits context ONLY when low power is ON (session start) or when the
# effective state flips mid-session (prompt). Silent otherwise. Always exit 0.

SENSE="$HOME/.claude/skills/fable-low-power/limit-sense.sh"
[[ -x "$SENSE" || -f "$SENSE" ]] || exit 0

STATE_JSON=$(bash "$SENSE" 2>/dev/null)
[[ -z "$STATE_JSON" ]] && exit 0

eval "$(/usr/bin/python3 -c "
import json, sys, shlex
try:
    d = json.loads('''$STATE_JSON''')
except Exception:
    sys.exit(0)
for k in ('effective', 'announced', 'mode', 'reason'):
    print(f'{k.upper()}={shlex.quote(str(d.get(k, \"\")))}')
print(f'U5={shlex.quote(str(d.get(\"five_hour\", \"?\")))}')
print(f'U7={shlex.quote(str(d.get(\"seven_day\", \"?\")))}')
print(f'R5={shlex.quote(str(d.get(\"five_hour_resets\", \"?\")))}')
print(f'R7={shlex.quote(str(d.get(\"seven_day_resets\", \"?\")))}')
print(f'FBURN={shlex.quote(str(d.get(\"fable_burn_str\", \"\")))}')
" 2>/dev/null)"
[[ -z "$EFFECTIVE" ]] && exit 0

case "${1:-session-start}" in
  session-start)
    if [[ "$EFFECTIVE" == "on" ]]; then
      echo "🪫 FABLE LOW POWER MODE — ON (${REASON}). Limits: 5h ${U5}% (resets ${R5}), 7d ${U7}% (resets ${R7})."
      [[ -n "$FBURN" ]] && echo "📈 Frontier burn: ${FBURN}."
      echo "Invoke Skill(fable-low-power) before substantive work. Standing order while ON: the frontier model spends tokens on judgment, planning, and verdicts ONLY — every execution step (reads, searches, builds, fixes, drafts) routes to subagents on cheaper models."
      bash "$SENSE" set-announced on >/dev/null 2>&1
    else
      bash "$SENSE" set-announced off >/dev/null 2>&1
    fi
    ;;
  prompt)
    if [[ "$EFFECTIVE" != "$ANNOUNCED" ]]; then
      if [[ "$EFFECTIVE" == "on" ]]; then
        echo "🪫 Low power mode just switched ON (${REASON}). Invoke Skill(fable-low-power): from this prompt forward the frontier model judges/plans only — all execution routes to cheaper-model subagents."
      else
        echo "🔋 Low power mode switched OFF (${REASON}). Normal routing resumes."
      fi
      bash "$SENSE" set-announced "$EFFECTIVE" >/dev/null 2>&1
    fi
    ;;
esac
exit 0
