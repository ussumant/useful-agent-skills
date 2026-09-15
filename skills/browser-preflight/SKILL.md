---
name: browser-preflight
description: >-
  Use BEFORE any task that needs to see or drive a browser or the screen
  (screenshots, UI review, deployed-site checks, computer-use tasks), and
  IMMEDIATELY when any browser or computer-use tool errors. Probes a channel
  ladder in order, names the first live one, and if every channel is dead
  DEGRADES the deliverable to an exact URL + numbered manual steps instead
  of failing the session. Trigger phrases: "screenshot the site", "check
  the deployed page", "review this UI", "computer-use task",
  "/browser-preflight", or any browser/computer-use tool call that just errored.
---

# Browser Preflight — the channel ladder

A task that needs eyes on a screen has one or more channels available —
a browser extension, a computer-use tool, a headless browser MCP — and any
of them can be unconnected, locked, or misconfigured on a given machine.
Without a preflight, an agent discovers this mid-task: it calls a dead
channel, gets an error, retries the same dead channel, and either burns the
whole task on retries or fails silently. Probe FIRST, once, then do the
real work on whichever channel answered.

## The ladder (stop at the first live rung)

This default order assumes a Claude Code-style setup with a browser
extension, a computer-use tool, and a headless browser MCP all installed.
Edit the list below to match your own setup — drop any rung you don't have,
reorder the rest.

1. **Browser extension (e.g. `claude-in-chrome`)** — load its tools if
   deferred, then call its lightweight "list tabs" / "get context" tool.
   Live → this is the channel: it drives a real, logged-in browser session.
2. **Computer-use tool** — one screenshot call. If it reports the screen
   is locked or held by another session, name what's holding it in one
   line, then keep going down the ladder rather than waiting on it.
3. **Headless browser MCP (e.g. gstack, Playwright)** — fast, scriptable,
   no logged-in state. Right for URL screenshots, QA flows, deploy
   verification. Say so up front if the task actually needs an
   authenticated session — this rung can't provide one.
4. **All rungs dead → degrade, don't die.** The deliverable becomes: the
   exact URL, numbered manual steps for a human to run, plus whatever
   analysis is possible without eyes (fetch and read the raw HTML/source).
   State plainly: "degraded deliverable — no live channel."

## Output contract

Before starting the real task, print one line:

`channel = <X> · fallback = <Y> · if all dead = <degraded deliverable>`

That line is the preflight verdict. If you can't write it, you haven't
preflighted — go probe the ladder first.

## Never retry a dead channel more than once

One failed call on a channel is a signal to move to the next rung, not to
retry the same call. Retrying a dead channel is how a whole task quietly
disappears into timeouts.

## Optional: automatic nudge hooks

Two optional hook scripts ship in this folder so the ladder runs even when
nobody remembers to invoke the skill by name:

- `preflight-nudge.sh` (`PreToolUse`, matched on browser/computer-use tool
  names) — fires once per session, before the *first* such call, injecting
  a reminder to preflight if it hasn't happened yet.
- `fail-nudge.sh` (`PostToolUseFailure`, same tool match) — fires once per
  session on the *first* browser/computer-use tool failure, feeding the
  ladder back in instead of letting the agent retry blind.

Both fail open (never block a session) and are opt-in — wire them in your
`settings.json` per the README if you want the automatic version; the skill
works fine invoked manually without them.
