---
name: size
description: >-
  Size a feature, PR, branch, or spec the way a dev team plans — check for
  reuse, name what we don't know, score five factors, roll into a T-shirt
  size (XS/S/M/L/XL), and split anything L or bigger into milestones that
  are each M or smaller. Also runs a predicted-vs-actual retro once work
  lands. Use on "size this", "how big is X", "t-shirt this", "estimate
  effort", "break this down", "how many milestones", "what do we not know",
  "retro", "predicted vs actual", or any request to plan effort before
  building.
---

# /size — T-shirt a feature and split it if it's too big

Sizing and breakdown are one move here. If a thing sizes L or XL, this skill
hands back milestones, each small enough to build and review on its own. It
also refuses to size fog: unknowns get named before factors get scored, and
every prediction gets checked against what actually happened once work
lands.

## Inputs

- A PR number: `/size 268`
- A branch name: `/size fix/retry-button`
- A spec or markdown file path: `/size docs/some-spec.md`
- Free text: `/size a retry button on a failed background job`
- `/size retro <PR # or card path>` — see Retro mode below

For a PR or branch, ground first — don't estimate from memory:
- `gh pr view <N> --json files,additions,deletions,mergeable,reviews,commits`
- `git rev-list --left-right --count origin/main...<branch>` (behind/ahead)
- File overlap against other open PRs (`gh pr diff` file lists, intersected)

For a spec or free text, read what's there. If a factor genuinely can't be
scored from it, ask up to 2 clarifying questions — no more.

## Unknowns gate — before you score anything

List every unknown the feature depends on: an unconfirmed mechanism, an API
behavior, a design choice, a reviewer ruling that hasn't happened. Each gets
a **how we'd resolve it** line — spike, ask a reviewer, read docs, prototype.

**Rule: 2+ unknowns that would change the design means this is not sized as
a build.** Milestone 0 becomes a time-boxed discovery spike (done-state: a
one-page answer per unknown), every milestone after it is marked **re-size
after spike**, and Uncertainty scores 3 automatically. Say plainly: "this is
not straightforward, expect N days of clarity work before building."

## Reuse scan — before you size anything

Check three places, record what you find even if it's nothing:

1. **Already in the repo** — grep for a similar mechanism/helper, name the file.
2. **Built before** — search prior specs/notes and closed PRs
   (`gh pr list --state merged --search "<keyword>" --repo <owner>/<repo>`
   — unscoped search silently hits the wrong repo) for prior work on this.
3. **Open source** — name a package that does this out of the box, one line
   on fit (a custom build for a good reason is a valid finding, not a miss).

Each hit that genuinely shrinks the work lowers Surface area or Uncertainty
by one point — show the arithmetic ("Uncertainty 3→2, existing helper
precedent"). If a hit doesn't move a score, say so rather than forcing a
discount.

## Factors — score each 1-3, one-line rationale required

| # | Factor | 1 | 2 | 3 |
|---|---|---|---|---|
| 1 | Surface area | one file/module | 2-4 modules | cross-cutting or shared protocol surface |
| 2 | Uncertainty | known mechanism, precedent in repo | known shape, new location | novel mechanism, or unknowns gate triggered |
| 3 | Integration risk | fresh base, no open-PR overlap | behind main but merges clean | conflicting, or touches files other open PRs touch |
| 4 | Verification cost | offline tests only | needs a staging/sandbox run or real browser | needs live paid runs or a production deploy to judge |
| 5 | Review load | one reviewer, one round expected | two rounds likely | novel territory needing a reviewer ruling, multi-round |

## Rollup

Sum the five scores (range 5-15):

| Sum | Size |
|---|---|
| 5-6 | XS |
| 7-8 | S |
| 9-10 | M |
| 11-12 | L |
| 13-15 | XL |

**Any single factor scored 3 bumps the floor to M**, even if the sum would
land lower. This catches the "small diff, terrifying blast radius" case the
sum alone would hide.

Also report **builder vs reviewer split** as separate T-shirts — the person
building and the person reviewing often carry different loads. A big review
load with a small diff still costs the reviewer real time even at builder XS.

## Output card — one screen

```
SIZE — <title>

Reuse scan: <hits, each with before→after score if it moved one>
Unknowns: <N> — <list + how each resolves> — gate <triggered/not triggered>

Factor            Score  Why
...

SIZE: L (sum 10, floor-bumped by integration risk=3)
Builder: M · Reviewer: S

## Predicted
Size / milestones / builder / reviewer / review rounds / calendar days

Milestones (required — L/XL, or gate triggered):
0. [if gated] Discovery spike — done: one-page answer per unknown
1. <name> — <size> — done: <observable state> — PR: <boundary> — depends on: <none/prior>

Ready to track this on a board? Say the word and I'll open one parent issue
+ one child per milestone wherever this team tracks work.
```

Skip the milestone block entirely for XS/S/M with no unknowns gate — there's
nothing to split.

## Milestone rule (L and XL, or gate triggered)

- Own **done-state** per milestone — observable, not "refactor the thing."
  A reviewer should look at it alone and say yes/no it happened.
- Own **PR boundary** per milestone — what's in it, what's next.
- Note dependencies between milestones (sequential vs parallel-safe).
- Each milestone independently sizes M or smaller, or split it again.
- **Gate triggered:** milestone 0 is always the spike; everything after it is
  "re-size after spike" — don't pretend to know sizes the spike hasn't
  resolved.

## Where cards land

- Default: `docs/sizing/SIZE-<slug>-<date>.md` inside the repo being sized.
- If that repo has no docs area for planning notes, use a sibling
  `sizing/` folder next to the repo, or wherever the team already keeps
  planning docs.
- Never bury a sizing card somewhere nobody will find it again — the retro
  step needs to find the same file later.

## Board handoff — gated, never automatic

The card always ends with an offer to open tracking issues. Only create
issues on an explicit go from the requester **in that conversation** — a
card in a markdown file is not consent. On yes, follow whatever board
convention this team already uses (parent issue = the feature/arc, one
sub-issue per milestone/PR) — don't invent a new convention here.

## Prediction-vs-actual retro — `/size retro <PR # or card path>`

Once a sized PR merges or feature completes, pull actuals from `gh`: commits,
review rounds, days open (`createdAt`→`mergedAt`), files touched. Append to
the same card:

```
## Actual
Size / milestones / builder / reviewer / review rounds / calendar days
delta: <one line — what the prediction missed and why>
```

Then add one row to `docs/sizing/CALIBRATION.md` (header row if new): date,
feature, predicted/actual size, predicted/actual rounds, predicted/actual
days, what we missed. This is how the rubric gets better instead of staying
a guess forever.

## Position in a typical planning loop

A reasonable order is idea → frame the problem → ground it in the existing
architecture → **size (here)** → write the full spec → build → review →
ship. Size runs after the idea is architecturally anchored and before the
full spec — sizing an unanchored idea just estimates fog. It also runs
standalone on any open PR, or as a retro once work lands.
