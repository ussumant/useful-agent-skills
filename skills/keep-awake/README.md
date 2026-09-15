# keep-awake

Don't let an overnight agent run die because the laptop went to sleep.

## Problem

You kick off a long unattended job — a full test suite, a multi-hour build,
an overnight agent loop — and walk away. The Mac idles, macOS sleeps it, and
whatever was running gets suspended or killed mid-flight. You come back to a
stalled or failed run and no idea how long it's been dead. A plain
`caffeinate &` from your terminal doesn't survive if that terminal session
gets interrupted or closed — which is exactly when you most need it to keep
running.

## What it does

- **Arms `caffeinate`** to hold the sleep assertion, plus a **detached
  guard process** (its own process group, PID file, nohup'd) that re-arms
  caffeinate within two minutes if it ever dies. The guard does not live
  inside your terminal or agent session — closing that session, or having it
  interrupted, does not take the guard down.
- **Proves it, doesn't assume it.** `status` reads the live `pmset -g
  assertions` output and reports whether the idle-sleep assertion is
  actually HELD right now, not just whether you ran the `on` command.
- **Time-boxed and self-expiring.** `on [hours]` (default 8) sets a window;
  the guard exits and releases caffeinate on its own when the window ends,
  so you don't need to remember to turn it off.

```text
$ ~/.claude/skills/keep-awake/keepawake.sh on 10
guard: RUNNING (pid 41213, ~600m left) — detached, survives session interrupts
sleep assertion: HELD (1 caffeinate process(es))
Now drawing from 'Battery Power'
CAVEAT: lid-close on battery sleeps the Mac regardless — leave the lid open (dark display is fine), plug in if possible.
```

## Before / after

Same scenario: an overnight test suite kicked off before bed, laptop
unattended for six-plus hours. Both images are renderings of a terminal
(the skill's own `status` output is real; the surrounding test-run lines are
illustrative, with example numbers). Transcripts in
[`examples/`](examples/).

Before: no guard armed. The lid closes on battery around 3am, the Mac
sleeps, and the suite stalls for six hours before anyone notices.

![before](examples/before.png)

After: `keepawake.sh on` armed before bed, with a proven pmset assertion.
The suite runs uninterrupted and `status` at the end still shows the guard
held.

![after](examples/after.png)

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the keep-awake skill globally from https://github.com/ussumant/useful-agent-skills and wire it up per its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill keep-awake --global --yes
```

No wiring needed beyond that — `keepawake.sh` is self-contained and creates
its own state directory (`~/.claude/keepawake` by default) on first run.

## How to use

```bash
~/.claude/skills/keep-awake/keepawake.sh on [hours]   # arm (default 8h); idempotent, extends the window
~/.claude/skills/keep-awake/keepawake.sh off          # stop guard + caffeinate
~/.claude/skills/keep-awake/keepawake.sh status       # guard state + live pmset proof + power source
```

Tell your agent "keep the laptop alive" or "don't let the computer sleep"
before any long unattended run and it will arm this skill; "keep-awake
status" or "keep-awake off" work the same way afterward.

## What's inside

- [`SKILL.md`](SKILL.md) — when and how an agent should arm/verify/release
  the guard, and the caveats it must always state
- [`keepawake.sh`](keepawake.sh) — the whole mechanism: `on` / `off` /
  `status`, the detached self-healing guard loop, and the pmset assertion
  check

## Honest caveats

- **macOS only.** Relies on `caffeinate` and `pmset`, both macOS-specific.
  There's no equivalent shipped here for Linux or Windows.
- **Lid-close on battery sleeps the Mac regardless of caffeinate.** This is
  a hardware/firmware behavior `caffeinate` cannot override. Leave the lid
  open (a dark display is fine) or stay plugged in.
- **The guard protects the machine, not your process.** It stops the Mac
  from sleeping; it does nothing to restart a job that crashed or was killed
  for reasons unrelated to sleep.
- **Requires `pmset` and `caffeinate` on `PATH`** (both ship with macOS by
  default) and a user account with permission to run them — no special
  privileges beyond that.

## License

MIT
