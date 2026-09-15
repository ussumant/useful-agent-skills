#!/bin/bash
# WIRED: PostToolUseFailure (match on browser/computer-use MCP tool names)
# fail-nudge.sh — browser-channel triage nudge.
#
# Sessions commonly die on a dead browser or computer-use channel by
# retrying the same dead channel, or by giving up quietly, instead of
# laddering to the next one. On the FIRST browser-tool failure of a
# session, feed the browser-preflight ladder back to the agent.
# Once per session (stamp); fails OPEN.

input=$(cat 2>/dev/null)
command -v jq >/dev/null 2>&1 || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ -n "$sid" ] && [ -n "$tool" ] || exit 0

# Edit this case to match the browser/computer-use tool prefixes you use.
case "$tool" in
  mcp__claude-in-chrome__*|mcp__chrome-devtools__*|mcp__computer-use__*|mcp__cua-driver__*|mcp__playwright__*) ;;
  *) exit 0 ;;
esac

state="$HOME/.claude/.hook-state/browser-preflight-fail"
mkdir -p "$state" 2>/dev/null || exit 0
find "$state" -type f -mtime +7 -delete 2>/dev/null   # opportunistic GC
[ -e "$state/$sid" ] && exit 0
printf '1' > "$state/$sid" 2>/dev/null

jq -cn --arg r "Browser channel failed (${tool}). Do NOT retry the dead channel blindly — run the browser-preflight ladder: (1) probe the browser extension channel; (2) probe computer-use with one screenshot — if locked, name WHICH session/app holds the lock; (3) fall back to a headless browser MCP. If every channel is dead, degrade the deliverable instead of failing the task: give the user the exact URL plus numbered manual steps. This nudge fires once per session." \
  '{decision:"block",reason:$r}'
exit 0
