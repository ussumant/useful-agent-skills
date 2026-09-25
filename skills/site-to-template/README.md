# site-to-template

Rebuild a website's look, layout and interactions as your own template, measured instead of eyeballed.

## Problem

"Make our page look like that site" usually ends in a rebuild from a
screenshot. It's close enough to fool a glance and wrong in every number:
the font falls back, the spacing drifts, the shadows go flat, and the page
ends up hundreds of pixels shorter. The playful parts get missed entirely
(stickers you can drag, hover pills, typing chat bubbles, rolling prices).
There's no way to say how close it is, so "done" is a feeling.

## What it does

- **Measures the source.** Computed styles for ~50 landmarks at desktop and
  phone width, and settled geometry measured after reveal animations finish.
- **Diffs the rebuild.** Every landmark box to ±2px, every style property
  (font, color, shadow, gradient, radius, padding), and matched section
  screenshots side by side.
- **Finds the interactions.** A Chrome DevTools Protocol inventory of every
  element with listeners, then a click-through to see what each does.
- **Samples motion instead of guessing:** typing speed, when a reply appears,
  whether a marquee is animated or scroll-linked, parallax rates.
- **Keeps the content yours.** Copy, photos, video, logos, people and
  characters are always replaced with original placeholders and art. Fonts
  come from open sources. The result is a template, not a mirror.

## Before / after

The same source page (a landing page written for this example, so the
screenshots carry no third-party content), rebuilt from a glance and then
with this skill. Numbers are from the skill's own `cmp.py` and `sdiff.py` on
the pages in [`examples/`](examples/).

Before: page 294 px short, 0 of 14 blocks within 2px, 170 of 238 style
properties matching.

![before](examples/before.png)

After: page height equal, 11 of 14 blocks within 2px (the misses are
placeholder text widths), 238 of 238 style properties matching.

![after](examples/after.png)

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the site-to-template skill globally from https://github.com/ussumant/useful-agent-skills and wire it up per its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill site-to-template --global --yes
```

Then install the one dependency (Playwright + Chromium):

```sh
cd ~/.claude/skills/site-to-template/scripts && npm i && npx playwright install chromium
```

## How to use

Ask for it in plain words: "rebuild https://example.com as a template for
our product", "get this page to fidelity with <url>", "copy the layout and
interactions of <url> with our content". The agent follows `SKILL.md`:
outline → tokens → settled geometry → build → box diff → style diff →
section shots → interaction inventory → motion sampling → phone pass.

Scripts run on their own too:

```sh
node scripts/geo.mjs https://example.com geo-ref.json 1440 900 config.json ref
node scripts/geo.mjs http://localhost:8787 geo-clone.json 1440 900 config.json clone
python3 scripts/cmp.py geo-ref.json geo-clone.json
```

## What's inside

`SKILL.md` (the workflow and the content boundary) and `scripts/`:

- `dump.mjs` and `geo.mjs`: measure the page (styles and settled boxes).
- `cmp.py` and `sdiff.py`: diff your clone against the source.
- `sections.mjs` and `sbs.py`: matched section screenshots.
- `interactions.mjs`: the listener inventory.
- `motion.mjs`: samples motion over time and scroll.
- `itest.template.mjs`: an interaction test to copy.
- `shoot.mjs`: full-page capture.

`examples/` holds the source page, both rebuilds, the config, and
`make-pair.mjs` that rendered the screenshots. Node with Playwright, and
python3 (`sbs.py` needs Pillow). Nothing phones home.

## Honest caveats

- **It measures the source page with a headless browser.** Respect the
  site's terms. The skill's output is a style template with your content,
  not a copy.
- **Headless Chromium can't play H.264.** Some video-backed decorations show
  blank in its screenshots.
- **The CDP inventory can't see everything.** It lists listeners, not what
  they do. The click-through step is still manual judgment.
- **Placeholder text of a different length moves text-sized boxes.** Box
  diffs on buttons and labels will stay off until your real copy is in.
