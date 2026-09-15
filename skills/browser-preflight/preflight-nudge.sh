#!/bin/bash
# WIRED: PreToolUse (match on browser/computer-use MCP tool names)
# preflight-nudge.sh — one-time-per-session reminder to run the
# browser-preflight ladder before the FIRST browser/screen tool call.
# Sessions can stall at step 0 on an unconnected extension or blocked
# screen access; this catches that before it burns the task.
# Never blocks — additionalContext only (a deny here could deadlock the
# preflight itself). Fails open.

IN=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
SID=$(printf '%s' "$IN" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$SID" ] || exit 0

STATE_DIR="$HOME/.claude/.hook-state/browser-preflight"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
find "$STATE_DIR" -type f -mtime +7 -delete 2>/dev/null   # opportunistic GC
MARK="$STATE_DIR/$SID"
[ -f "$MARK" ] && exit 0        # already nudged this session
touch "$MARK" 2>/dev/null

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"[browser-preflight] First browser/screen tool call of this session. If the browser-preflight skill has NOT run yet this session, run it now before continuing: probe the channel ladder (browser extension -> computer-use -> headless browser MCP), stop at the first live rung, or degrade to an exact URL + numbered manual steps if every rung is dead. Whole sessions have stalled at step 0 on an unconnected channel."}}
JSON
exit 0
