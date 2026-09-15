# browser-preflight

Stop losing a whole task to a browser channel that was dead from the start.

## Problem

A task that needs to see or drive a browser — a screenshot, a UI review, a
deployed-site check, a computer-use flow — depends on some channel actually
being connected: a browser extension, a computer-use tool, a headless
browser MCP. Any of them can be unconfigured, locked, or logged out on a
given machine. Without a preflight, an agent finds this out mid-task: it
calls a dead channel, gets an error, retries the same dead channel a few
times, and either burns the task on retries or gives up with "could not
verify" — when a different channel on the same machine was live the whole
time.

## What it does

- **Defines a channel ladder** — an ordered list of browser/screen channels
  to try, stopping at the first one that answers.
- **Probes once per channel, not repeatedly** — one lightweight call per
  rung (list tabs, one screenshot) rather than retrying a dead tool.
- **Names the channel it picked**, in one line, before the real task
  starts, so the rest of the session (and anyone reading the transcript)
  knows which channel is doing the work and what its limits are (e.g. "no
  logged-in state").
- **Degrades instead of failing** when every rung is dead: the deliverable
  becomes the exact URL plus numbered manual steps for a human, plus
  whatever can be done without eyes (fetch and read the raw page source).
- **Optional hooks** re-fire the same ladder automatically: once before the
  first browser tool call of a session, and once on the first browser-tool
  failure — so the ladder runs even if nobody remembers to invoke it.

## Before / after

Same task — verify a deployed landing page renders after a deploy — with
one variable changed: whether the preflight ladder ran first. Both images
are renderings of real terminal output in the skill's actual format, with
example tool/channel names standing in for a real setup. Transcripts in
[`examples/`](examples/).

**Before:** the agent calls a dead browser tool, retries it three times,
then gives up with "could not verify."

![before](examples/before.png)

**After:** the ladder finds the first channel dead, the second live, uses
it — and, in the all-dead case, degrades cleanly to a URL and manual steps
instead of failing silently.

![after](examples/after.png)

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the browser-preflight skill globally from https://github.com/ussumant/useful-agent-skills and wire it up per its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill browser-preflight --global --yes
```

The skill itself needs nothing else — it's pure instructions your agent
loads on trigger. The two hook scripts are optional automation on top; wire
them in `~/.claude/settings.json` if you want the ladder enforced even when
nobody says "preflight the browser":

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__claude-in-chrome__.*|mcp__chrome-devtools__.*|mcp__computer-use__.*|mcp__cua-driver__.*",
        "hooks": [ { "type": "command", "command": "bash ~/.claude/skills/browser-preflight/preflight-nudge.sh" } ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "mcp__claude-in-chrome__.*|mcp__chrome-devtools__.*|mcp__computer-use__.*|mcp__cua-driver__.*",
        "hooks": [ { "type": "command", "command": "bash ~/.claude/skills/browser-preflight/fail-nudge.sh" } ]
      }
    ]
  }
}
```

Edit the matcher/case statement in both scripts to match the browser tools
you actually have installed — the shipped list is a Claude Code-oriented
starting point, not exhaustive.

## How to use

Say "preflight the browser" or "/browser-preflight", or just start a task
that needs a browser/screen — the skill's trigger phrases in `SKILL.md`
cover the common cases, and (if wired) the hooks nudge it automatically.
The skill has the agent print one line before doing the real work:

```text
channel = <X> · fallback = <Y> · if all dead = <degraded deliverable>
```

## What's inside

- [`SKILL.md`](SKILL.md) — the channel ladder, the output contract, and the
  "never retry a dead channel more than once" rule the agent loads on
  trigger.
- [`preflight-nudge.sh`](preflight-nudge.sh) — optional `PreToolUse` hook,
  fires once per session before the first browser/computer-use tool call.
- [`fail-nudge.sh`](fail-nudge.sh) — optional `PostToolUseFailure` hook,
  fires once per session on the first browser/computer-use tool failure.

## Honest caveats

- The default ladder's channel *names* (a browser extension, a
  computer-use tool, a headless browser MCP) describe Claude Code's own
  tool ecosystem — swap in whatever your harness actually exposes; the
  ladder pattern (probe in order, stop at first live, degrade if all dead)
  is the reusable part, not the specific tool names.
- Every probe is best-effort: a channel reporting "live" on a lightweight
  call (list tabs, one screenshot) is not a guarantee the real task's
  calls will all succeed — it just means the channel answered at all.
- The hooks fail open by design (never block a session) and only fire once
  per session id — restart the session to see the nudge again while
  testing.

## License

MIT
