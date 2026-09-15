# explainer-diagrams

Turn an explanation into a diagram that reads at a glance, in one consistent
visual grammar, as a PNG you can drop into a post.

## Problem

You ask your agent for "a diagram" and get one of two things: a Mermaid
flowchart that looks like every other Mermaid flowchart, or a table with
colored borders. Neither is a picture. Readers skim past both. And every new
diagram comes out in a different style, so a post with six of them looks like
six different people made it.

## What it does

- **One grammar, reused.** A pixel-font title, a mono subtitle, white cards
  with a blue stroke, orange for anything that came from outside, dashed
  containers, network circles, stat tiles, and a one-line callout. Every
  diagram you make with it matches the last one.
- **Scenes, not tables.** The skill's rules push the agent toward shapes that
  carry meaning: a timeline that thickens as something grows, a path that
  stops short with an `×`, a hollow node next to solid ones, a bar split into
  scored segments. Quotes stay under fourteen words. Nothing under 13px.
- **A catalogue of seven proven shapes** (timeline with growth, ranked bars
  with source and output, fork into two minds, two tracks with rewind, stat
  tiles and stacked bar, fail-to-rule ladder, before/after) with the finished
  examples included, so the agent copies a working scene instead of inventing
  a layout.
- **A screenshot harness** that shoots each diagram to a 2× PNG, waits for the
  font to load, and asserts it, so you never ship a fallback-font render.
- **A QA checklist the agent must run by eye** on every PNG: arrowheads
  present, nothing crossing, nothing clipped, facts matching the source.

## Before / after

The same content, "how a pull request gets merged", the way an agent usually
emits it (a table in a doc) and the way this skill emits it (a scene). Both
rendered from the HTML in [`examples/general/`](examples/general/).

Before:

![before](examples/before.png)

After:

![after](examples/after.png)

Seven more finished diagrams, from a longer write-up, in
[`examples/severance-week/out/`](examples/severance-week/out/) with their
source HTML and plan.

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the explainer-diagrams skill globally from https://github.com/ussumant/useful-agent-skills and read its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill explainer-diagrams --global --yes
```

Then make sure the harness can find puppeteer:

```sh
npm i -g puppeteer          # or: npm i puppeteer in the folder where you keep diagrams
# or point at an existing install:
export PUPPETEER_PATH=/path/to/node_modules/puppeteer
```

## How to use

Say what you want explained and where it will go:

```text
Make this a diagram for the post: the retrieval step handed the model eight memories,
seven were the character's own reflections about being noticed, and the output was the
line "let it just be the room noticing." Source rows are in memory.db ids 3438, 2542, ...
```

The agent writes a content sheet (title, subtitle, the few words that will
appear, the callout, which catalogue shape), builds the scene in a copy of
`template.html`, shoots it, looks at the PNG, fixes, and hands you the PNG.
You will usually want one round on wording. That is expected and cheap.

## What's inside

```text
SKILL.md              the grammar, the rules, the catalogue, the workflow, the checklist
template.html         shared CSS + two starter diagrams that render as-is
components.md         copy-paste snippets: cards, arrows, circles, timelines, bars, ladders
shoot.mjs             puppeteer harness: plan.json in, PNGs out
plan.example.json     the plan shape (viewport, font wait, one shot per #shotN)
examples/             seven finished diagrams: source HTML, plan, and PNGs
```

## Honest caveats

- It needs Node and puppeteer, and network access to Google Fonts for the
  pixel title font. Offline, the title falls back to a system sans and the
  harness tells you.
- Output is a PNG, not an editable diagram. Edit the HTML and re-shoot.
- The grammar is opinionated (blue/orange, mono, pixel titles). It was built
  for long-form writing about systems and experiments. If your brand needs
  other colors, change the six variables at the top of `template.html`; the
  rules still apply.
- Text sizes are tuned for a PNG displayed around 700px wide. On a
  full-width slide the type will look small.
- The agent still has to look at every PNG. The harness catches missing
  fonts, not missing arrowheads; the checklist does, if it is followed.
