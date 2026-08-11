#!/bin/bash
# limit-sense.sh — live Anthropic usage-limit sensor for fable-low-power mode.
#
# Source of truth: ~/.claude/cache/statusline-payload.json — the JSON payload
# Claude Code pipes into the statusline per render tick, teed there by
# statusline-tee.sh (or your own statusline with the tee block grafted in).
# Carries rate_limits.five_hour / .seven_day used_percentage + resets_at.
# Zero credentials involved.
#
# Usage:
#   limit-sense.sh                      print JSON decision state
#   limit-sense.sh set-mode <auto|on|off>
#   limit-sense.sh set-announced <on|off>
#
# State: ~/.claude/fable-low-power.json (mode, thresholds, model_match)
# Always exits 0 — a sensor must never break a hook chain.

PAYLOAD="$HOME/.claude/cache/statusline-payload.json"
STATE_FILE="$HOME/.claude/fable-low-power.json"

if [[ ! -f "$STATE_FILE" ]]; then
  cat > "$STATE_FILE" <<'EOF'
{
  "mode": "auto",
  "announced": "off",
  "last_effective": "off",
  "thresholds": { "on_5h": 60, "on_7d": 75, "off_5h": 40, "off_7d": 65 },
  "model_match": "fable",
  "updated": null
}
EOF
fi

case "${1:-}" in
  set-mode)
    /usr/bin/python3 - "$STATE_FILE" "$2" <<'PYEOF'
import json, sys, datetime
path, mode = sys.argv[1], sys.argv[2]
if mode not in ("auto", "on", "off"):
    print(json.dumps({"ok": False, "error": f"bad mode {mode!r} (auto|on|off)"})); sys.exit(0)
s = json.load(open(path))
s["mode"] = mode
s["updated"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
json.dump(s, open(path, "w"), indent=2)
print(json.dumps({"ok": True, "mode": mode}))
PYEOF
    exit 0 ;;
  set-announced)
    /usr/bin/python3 - "$STATE_FILE" "$2" <<'PYEOF'
import json, sys
path, val = sys.argv[1], sys.argv[2]
s = json.load(open(path))
s["announced"] = val
json.dump(s, open(path, "w"), indent=2)
PYEOF
    exit 0 ;;
esac

/usr/bin/python3 - "$PAYLOAD" "$STATE_FILE" <<'PYEOF'
import json, sys, os, datetime, time
payload_path, state_path = sys.argv[1], sys.argv[2]
state = json.load(open(state_path))
th = state["thresholds"]

u5 = u7 = None
r5 = r7 = None
age_min = None
try:
    age_min = (time.time() - os.stat(payload_path).st_mtime) / 60
    rl = json.load(open(payload_path)).get("rate_limits", {})
    u5 = rl.get("five_hour", {}).get("used_percentage")
    u7 = rl.get("seven_day", {}).get("used_percentage")
    r5 = rl.get("five_hour", {}).get("resets_at")
    r7 = rl.get("seven_day", {}).get("resets_at")
except Exception:
    pass
# The payload sometimes carries float percentages — round for sane display
# (1% granularity is plenty for threshold decisions too).
u5 = round(u5) if u5 is not None else None
u7 = round(u7) if u7 is not None else None

# Frontier-vs-worker burn, aggregated from the per-session ledger the
# statusline tee writes (usage-sessions/<id>.json, cumulative per session).
# "frontier" = sessions whose MAIN loop model id contains model_match —
# their cost_usd includes in-session subagents. Workers = interactive
# sessions on other models; headless -p runs never tick a statusline,
# so they don't appear here.
mm = str(state.get("model_match", "fable")).lower()
udir = os.path.join(os.path.dirname(payload_path), "usage-sessions")
fable_today = {"sessions": 0, "cost_usd": 0.0, "in_tokens": 0, "out_tokens": 0}
fable_7d = {"sessions": 0, "cost_usd": 0.0, "out_tokens": 0}
workers_today = {"sessions": 0, "cost_usd": 0.0}
now = time.time()
today = datetime.date.today()
try:
    for fn in os.listdir(udir):
        if not fn.endswith(".json"):
            continue
        p = os.path.join(udir, fn)
        try:
            mt = os.stat(p).st_mtime
            if now - mt > 8 * 86400:
                os.unlink(p)
                continue
            rec = json.load(open(p))
        except Exception:
            continue
        is_frontier = mm in str(rec.get("model", "")).lower()
        is_today = datetime.date.fromtimestamp(mt) == today
        if is_frontier:
            if now - mt <= 7 * 86400:
                fable_7d["sessions"] += 1
                fable_7d["cost_usd"] += rec.get("cost_usd") or 0
                fable_7d["out_tokens"] += rec.get("out_tokens") or 0
            if is_today:
                fable_today["sessions"] += 1
                fable_today["cost_usd"] += rec.get("cost_usd") or 0
                fable_today["in_tokens"] += rec.get("in_tokens") or 0
                fable_today["out_tokens"] += rec.get("out_tokens") or 0
        elif is_today:
            workers_today["sessions"] += 1
            workers_today["cost_usd"] += rec.get("cost_usd") or 0
except Exception:
    pass
for d in (fable_today, fable_7d, workers_today):
    d["cost_usd"] = round(d["cost_usd"], 2)

# Preformatted one-liner for the banner hook — formatting lives HERE because
# this heredoc is immune to bash quoting; low-power-mode.sh's nested
# eval/$()/python -c layers (macOS ships bash 3.2, which mangles f-strings
# with quoted call-args inside braces there). The hook extracts flat scalars.
def _kt(n):
    return f"{n/1000:.1f}k" if n >= 1000 else str(n)
fable_burn_str = ""
if fable_today["sessions"]:
    s = fable_today["sessions"]
    fable_burn_str = (f"today {s} frontier session{'s' if s != 1 else ''}"
                      f" · ${fable_today['cost_usd']}"
                      f" · {_kt(fable_today['out_tokens'])} tok out")
    if fable_7d["sessions"]:
        fable_burn_str += f" · 7d ${fable_7d['cost_usd']}"
    if workers_today["sessions"]:
        fable_burn_str += f" · workers today ${workers_today['cost_usd']}"

mode = state.get("mode", "auto")
last = state.get("last_effective", "off")
fresh = age_min is not None and age_min <= 30 and u5 is not None

if mode in ("on", "off"):
    effective, reason = mode, f"manual {mode}"
elif not fresh:
    effective, reason = last, "no fresh rate-limit reading, holding last state"
elif last == "off" and (u5 >= th["on_5h"] or (u7 or 0) >= th["on_7d"]):
    effective, reason = "on", f"5h={u5}% 7d={u7}% crossed on-threshold ({th['on_5h']}%/{th['on_7d']}%)"
elif last == "on" and u5 < th["off_5h"] and (u7 or 0) < th["off_7d"]:
    effective, reason = "off", f"5h={u5}% 7d={u7}% below off-threshold ({th['off_5h']}%/{th['off_7d']}%)"
else:
    effective, reason = last, f"5h={u5}% 7d={u7}% holds current state"

if effective != last:
    state["last_effective"] = effective
    state["updated"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    json.dump(state, open(state_path, "w"), indent=2)

def fmt_reset(ts):
    if not ts:
        return None
    return datetime.datetime.fromtimestamp(ts).astimezone().strftime("%a %H:%M")

print(json.dumps({
    "effective": effective,
    "mode": mode,
    "reason": reason,
    "five_hour": u5,
    "seven_day": u7,
    "five_hour_resets": fmt_reset(r5),
    "seven_day_resets": fmt_reset(r7),
    "reading_age_min": round(age_min, 1) if age_min is not None else None,
    "announced": state.get("announced", "off"),
    "fable_today": fable_today,
    "fable_7d": fable_7d,
    "workers_today": workers_today,
    "fable_burn_str": fable_burn_str,
}))
PYEOF
exit 0
