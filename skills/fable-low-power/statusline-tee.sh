#!/bin/bash
# statusline-tee.sh — minimal Claude Code statusline that feeds fable-low-power.
#
# Claude Code pipes a JSON payload into the statusline command on every render
# tick. This script:
#   1. Tees the raw payload to ~/.claude/cache/statusline-payload.json
#      (limit-sense.sh reads it for live rate-limit signals — no credentials)
#   2. Snapshots this session's cumulative model/cost/token totals to
#      ~/.claude/cache/usage-sessions/<session_id>.json (atomic overwrite per
#      tick, last write wins = session totals) — the frontier-usage ledger
#   3. Prints a one-line status: model · 5h/7d usage · low-power state
#
# Already have a statusline script? Keep it — graft the block between
# TEE-START and TEE-END into it and keep your own rendering.
#
# NOTE: `cat > payload` consumes stdin. If your own script reads stdin again
# later, read the teed payload file instead — a second `cat` gets nothing.

CACHE_DIR="$HOME/.claude/cache"
STATE_FILE="$HOME/.claude/fable-low-power.json"

# --- TEE-START ---
mkdir -p "$CACHE_DIR"
if [[ ! -t 0 ]]; then
    cat > "$CACHE_DIR/statusline-payload.json" 2>/dev/null
fi
P="$CACHE_DIR/statusline-payload.json"
SID=$(grep -o '"session_id" *: *"[^"]*"' "$P" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
if [[ -n "$SID" ]]; then
    MODEL=$(grep -o '"model" *: *{ *"id" *: *"[^"]*"' "$P" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    COST=$(grep -o '"total_cost_usd" *: *[0-9.]*' "$P" | head -1 | grep -o '[0-9.]*$')
    TIN=$(grep -o '"total_input_tokens" *: *[0-9]*' "$P" | head -1 | grep -o '[0-9]*$')
    TOUT=$(grep -o '"total_output_tokens" *: *[0-9]*' "$P" | head -1 | grep -o '[0-9]*$')
    mkdir -p "$CACHE_DIR/usage-sessions"
    TMP="$CACHE_DIR/usage-sessions/.tmp.$$"
    printf '{"session_id":"%s","model":"%s","cost_usd":%s,"in_tokens":%s,"out_tokens":%s,"ts":%s}\n' \
        "$SID" "${MODEL:-unknown}" "${COST:-0}" "${TIN:-0}" "${TOUT:-0}" "$(date +%s)" \
        > "$TMP" 2>/dev/null && mv -f "$TMP" "$CACHE_DIR/usage-sessions/$SID.json"
fi
# --- TEE-END ---

U5=$(grep -o '"five_hour" *: *{ *"used_percentage" *: *[0-9]*' "$P" 2>/dev/null | grep -o '[0-9]*$')
U7=$(grep -o '"seven_day" *: *{ *"used_percentage" *: *[0-9]*' "$P" 2>/dev/null | grep -o '[0-9]*$')
LP=$(grep -o '"last_effective" *: *"[^"]*"' "$STATE_FILE" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/')
ICON="🔋"; [[ "$LP" == "on" ]] && ICON="🪫"
echo "${ICON} ${MODEL:-?} · 5h ${U5:-?}% · 7d ${U7:-?}%"
