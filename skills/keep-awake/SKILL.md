---
name: keep-awake
description: >-
  Keep a Mac awake for unattended/overnight agent runs — caffeinate plus a
  DETACHED self-healing guard that a session interrupt cannot kill, with
  pmset verification so "armed" is proven, never assumed. Use when: "keep
  the laptop alive", "don't let the computer sleep", "I'm going away /
  overnight run", or before launching any long unattended lane. Also:
  "keep-awake off/status".
---

# keep-awake — the machine stays up, provably

All mechanics live in `keepawake.sh` next to this file. The skill decides;
the script writes. Two failure modes motivate the design: a laptop that
silently sleeps mid-run and takes a long unattended job down with it, and a
guard that dies the moment the session that launched it gets interrupted or
restarted. So the guard here is a **detached OS process** that a Claude
session interrupt cannot reach.

## Commands

```bash
~/.claude/skills/keep-awake/keepawake.sh on [hours]   # arm (default 8h) + verify; idempotent (extends window)
~/.claude/skills/keep-awake/keepawake.sh off          # stop guard + caffeinate
~/.claude/skills/keep-awake/keepawake.sh status       # guard state + LIVE pmset assertion proof + power source
```

Set `KEEPAWAKE_DIR` to change where state lives (default `~/.claude/keepawake`).

## Rules

1. **Arm BEFORE any long unattended run** (build lanes, overnight test
   suites, batch jobs) — and whenever the user says they're stepping away.
   Default 8h; size the window to the work.
2. **Verify, never assume.** `on` ends with the pmset assertion check;
   report what it PROVED ("sleep assertion: HELD"), not what you launched.
   If the assertion is not held, say so and investigate — do not claim
   armed.
3. **The guard is detached** (nohup, own process group, PID file under
   `$KEEPAWAKE_DIR`) — it re-arms caffeinate within 2 minutes if it dies and
   survives session interrupts, session restarts, and turn kills. Do NOT
   replace it with a session-held background task — a background job tied to
   the calling session dies exactly when the session does, which defeats the
   point.
4. **Honesty caveat, always stated:** lid-close on battery sleeps the Mac
   regardless of caffeinate. Tell the user: leave the lid open (dark display
   is fine), plug in when possible. On AC power the machine also tends to
   hold without caffeinate — the guard is belt-and-suspenders, keep it
   anyway.
5. **Keep-awake protects the MACHINE, not the LOOP.** It stops the laptop
   from sleeping; it does not restart a crashed process or resume an
   interrupted agent. If the unattended work also needs to survive its own
   crashes, pair this with whatever process-supervision or heartbeat
   mechanism that workflow already uses.
6. `off` when the run completes — don't leave a machine pinned awake for
   nothing (battery + thermals). The window auto-expires anyway.
