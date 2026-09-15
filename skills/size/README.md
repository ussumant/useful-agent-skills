# size

T-shirt a feature and split it if it's too big — before anyone starts building.

## Problem

"How big is this?" usually gets answered from vibes: a round number with no
breakdown, no check for what's already built, and no list of what could
still change the design. The estimate turns out to hide unknowns that blow
up scope days later, and there's nothing to compare the guess against once
the work actually lands.

## What it does

- **Scans for reuse first** — checks the repo, prior closed work, and open
  source before scoring anything, so an existing helper actually shrinks
  the estimate instead of getting re-invented.
- **Names unknowns before scoring** — 2 or more unknowns that could change
  the design means this isn't sized as a build; it becomes a discovery
  spike milestone instead of a guess.
- **Scores five factors** (surface area, uncertainty, integration risk,
  verification cost, review load) 1-3 each, sums them into an XS–XL
  T-shirt size, with a rule that any single 3 bumps the floor to M.
- **Splits anything L or bigger** into milestones that each independently
  size M or smaller, with their own done-state and PR boundary.
- **Runs a retro** once work lands — `/size retro` pulls real commits,
  review rounds, and days-open from `gh` and logs predicted vs actual.

## Before / after

The same request — "add CSV export to the reports page" — with and without
the skill. Both images are renderings of the skill's real output format,
with example content standing in for a real project (the numbers are
illustrative, not from a real estimate). Transcripts in
[`examples/`](examples/).

Before: a one-line guess with no breakdown, no reuse check, no named
unknowns — the scope creep shows up days later instead of up front.

![before](examples/before.png)

After: a reuse scan, a named unknowns list that gates the estimate, five
scored factors, a T-shirt size with the arithmetic shown, and a milestone
plan split at the discovery spike.

![after](examples/after.png)

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the size skill globally from https://github.com/ussumant/useful-agent-skills and wire it up per its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill size --global --yes
```

No hooks, no state file, no dependencies — `SKILL.md` is the whole
mechanism. It only needs `gh` on your `PATH` when you size a PR or branch,
and `git` for the ahead/behind check.

## How to use

```text
/size 268                                  → size an open PR by number
/size fix/retry-button                     → size a branch
/size docs/some-spec.md                    → size a written spec
/size a retry button on a failed job       → size free text
/size retro 268                            → predicted-vs-actual once it ships
```

The skill asks up to 2 clarifying questions when a factor genuinely can't
be scored from what's given — never more, and never silently guesses.

## What's inside

- [`SKILL.md`](SKILL.md) — the full method: inputs, unknowns gate, reuse
  scan, five-factor rubric, rollup table, output card format, milestone
  rule, and the retro procedure.
- [`examples/`](examples/) — the before/after transcripts and renders.

## Honest caveats

- This is a planning-conversation aid, not an estimate you bill a client
  on — the five factors are a structured way to talk about size, not a
  calibrated statistical model.
- The rubric only gets better if you actually run the retro; skip it
  enough times and the sizes drift back to vibes with extra steps.
- It leans on `gh` for PR/branch grounding — without a GitHub remote and
  the CLI authenticated, PR and branch inputs fall back to whatever you
  can paste in as free text.
- Sizing an idea that hasn't been architecturally anchored yet just
  estimates fog with more structure; ground the idea first if you can.

## License

MIT
