---
name: explainer-diagrams
description: Build explainer diagrams as HTML+SVG scenes in one consistent visual grammar (pixel-font title, mono subtitle, blue/orange cards and arrows, dashed containers, network circles, stat tiles, a one-line callout) and shoot each to a PNG with puppeteer. Use whenever a concept, story, trace, comparison, or set of numbers should be explained visually for a blog post, newsletter, thread, slide, doc, or PR ("make this a diagram", "explain it visually", "the diagrams look boring", "diagram for the post"). Scenes, not tables.
---

# Explainer diagrams

A diagram in this grammar is a **scene**: shapes, positions, and arrows that
carry the meaning, with few words. The first attempt at this usually comes
out as a table in nice colors. The verdict that produced this skill was
"they're not visual, they look boring." Read `examples/severance-week/`
before your first diagram: `index.html` is the source of seven diagrams and
`out/` holds the PNGs they produced. That is the reference implementation.

## The grammar

| token | value | used for |
|---|---|---|
| blue `#1a52e0` | flow, structure, the real thing | card strokes, solid arrows, solid nodes, stat numbers, index badge |
| orange `#d66b2f` | intervention, return path, the outside hand | dashed arrows, seed cards (`#fff3ea` tint), rewind |
| panel `#f5f7ff` | containers, callouts | dashed container fill, callout background |
| gray `#aaa` / `#f2f2f2` | invalid, scripted, never happened | hollow nodes, struck-through lines, "never entered" boxes |
| text `#666`, muted `#767676`, ink `#000` | | |

Type: **Pixelify Sans** (Google Fonts) for the title and the callout heading
only; system mono for everything else; system sans bold only for card labels
and node names. Cards are white, 1px stroke, `border-radius: 3px`. Arrows use
a 6×6 triangle `<marker>`, one per diagram with a unique id.

Components (all in `template.html`): `.shot` (1100px white sheet, 40px
padding; the PNG is this element) → `.shot-head` (blue mono index `01`,
Pixelify `<h2>`, one-line mono `<p>`) → `.scene` (1020px, `#fbfbfb`, 1px
border; the picture) → optional `.stat-row` of `.stat-tile` (big blue mono
number over a gray label) → optional `.callout` (blue left border, Pixelify
one-liner + one mono sentence) → optional `.footnote` (11px mono caveat).
Card variants: `.tint-orange`, `.tint-blue`, `.solid`, `.dashed`, `.gray`;
inside a card: `.tag` (mono caps), `.label` (sans bold), `.sub` (mono body).
`components.md` has copy-paste snippets for every piece.

## Scene, not table

- One idea per diagram. The title says it, the scene shows it, the callout
  says what it means in one line. If it needs a paragraph, it is two diagrams.
- Shapes carry the meaning: a line that thickens day by day, a path that
  stops short of a box with an `×`, a hollow node beside solid ones, a
  strike-through on the canned line, a bar split into scored segments. The
  reader should get it before reading a word.
- Words are receipts, not prose: quotes ≤ 14 words with an ellipsis, never
  reworded; ids and times in mono beside them; ≤ ~10 text objects per scene.
- Nothing smaller than 13px at the 1020px scene. Most newsletter and forum
  layouts show the PNG at ~700px wide. Stat numbers 24px, titles 27px.
- Every number and quote comes from a source file, verbatim. A caption or a
  callout is a factual claim; check it against the source before shooting.
- Footnotes carry method caveats. Never reference an unpublished URL or
  "see 01–06 above" inside a PNG that will travel on its own.

## Scene catalogue (proven shapes)

| shape | use when | example in `out/` |
|---|---|---|
| **Timeline with growth**: day columns, quote cards, a baseline that thickens; a seed card + dashed orange edge into the person it entered | one input, days of consequence | 13-one-paragraph-five-days |
| **Ranked bars with a source and an output**: question card → rows, each a bar in three stacked score segments + id/day/snippet → solid output card, dashed return edge | "how did this output get made", any retrieval or ranking trace | 20-how-one-line-got-made |
| **Fork, two minds**: one orange dashed input card → two circles → two vertical chains of cards; a gray dashed "never happened" box off to the side; pixel-font verdict words under each chain | same input, different interpretations | 19-same-whisper-two-minds |
| **Two tracks with rewind**: gray hollow track with a struck-through line and an `invalid` end node; orange dashed rewind arrow; blue solid track with timed nodes | a run that was redone, before/after in time | 22-two-fridays |
| **Stat tiles + stacked bar**: five tiles, one wide bar with the dominant segment labeled with its share, legend with exact figures | cost, counts, any "where does it go" | 24-by-the-numbers |
| **Fail → rule ladder**: orange-tinted fail cards → blue arrows → white rule cards inside a tinted column | what broke and what it became; postmortems | 25-what-didnt-work |
| **Before / after**: naive chain (a grayed missing piece with a red `×` badge) beside the full loop (dashed container, return edges, outer dashed loop), pixel-font footer under each | architecture comparison | 03-before-after-architecture |

New shapes are welcome inside the grammar above.

## Workflow

1. **Content sheet first.** For each diagram: title, one-line subtitle, the
   ≤ 10 text objects with their source ids, the callout line, and the shape
   from the catalogue. If the diagrams are for something the user publishes,
   get their approval on the wording here; wording is taste, layout is
   plumbing.
2. **Build** in a copy of `template.html`: one `<div id="shotN" class="shot">`
   per diagram. HTML cards for anything with text (native wrapping); SVG only
   for connectors, circles, bars, and baselines. Cards over SVG, never SVG
   `<text>` for sentences.
3. **Shoot** with `shoot.mjs` and a plan modeled on `plan.example.json`:
   viewport 1300×1000, `deviceScaleFactor: 2`, wait for
   `document.fonts.status === 'loaded'` **and** assert
   `document.fonts.check('1em "Pixelify Sans"')` before the first shot, one
   `{type:"shot", selector:"#shotN", path}` per diagram, absolute paths.
4. **Look at every PNG** (open it, or read it with a vision-capable tool).
   `ok:true` from the harness is not a pass. Run the checklist below, fix,
   re-shoot only the changed diagrams.
5. **Show the PNGs, not the HTML.** Expect one round on wording and one on a
   missing arrow; both are normal.

If you delegate, steps 2–4 are mechanical enough for a cheaper model given
this file and the example; step 1 and the final look are not.

## Commands

```bash
SK=~/.claude/skills/explainer-diagrams
mkdir -p ./diagrams && cp $SK/template.html ./diagrams/index.html
# edit index.html; write ./diagrams/plan.json from $SK/plan.example.json (absolute paths)
node $SK/shoot.mjs ./diagrams/plan.json     # one JSON line per eval step + a final {ok}
```

Requirements: Node 18+, puppeteer (`npm i puppeteer` anywhere the loader can
find it: local `node_modules`, `PUPPETEER_PATH`, or the global npm root), and
network access to Google Fonts for Pixelify Sans. If the plan's
`fonts.check` eval returns `false`, the shot is in a fallback font and must
be redone.

## QA checklist (every PNG, by eye)

- Pixel font rendered in the title (blocky), not a fallback sans.
- Every arrow has a visible head. Heads vanish when a path ends inside its
  target box (the box fill paints over the marker): end paths at the box edge.
- No label crosses an arrow; no text touches a circle stroke; nothing is
  clipped at the scene edge; no column leaves a large void.
- Text ≥ 13px-equivalent; quotes ≤ 14 words; ids present where quotes are.
- Callout and captions match the source facts.
- The scene reads at a glance with the words covered.

## Gotchas

- Adding text under rows grows row heights and moves anchored arrows; re-view
  after any content change.
- A return edge from "nowhere" reads as decoration; anchor both ends to
  elements.
- A label sitting on a dashed path reads as strike-through; stack the path
  (SVG) and the label (HTML) in normal flow instead.
- Marker ids collide across diagrams on one page; prefix them (`d3-m1`).
- The first row of a ladder needs its antecedent ("Theo's last call", not
  "His last call"): the PNG travels without the paragraph.

## Files

`template.html` (shared CSS + two starter diagrams that render as-is) ·
`components.md` (snippets for every component and connector) · `shoot.mjs`
(the screenshot harness) · `plan.example.json` (the plan shape) ·
`examples/severance-week/` (seven finished diagrams: source, plan, PNGs).
