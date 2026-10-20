# release-clip

Make a 20–30 second clip of your feature, recorded live at true speed and cut
into a short story. You get an mp4 and a poster for your site, and a GIF that
plays inside a GitHub README.

## Problem

You ship something and want a short video of it working. You ask your agent
for a demo clip, and it reaches for `page.screencast()` or a pile of
screenshots. What comes back is the whole window at 1x, so the text is a smudge
at website width. Nothing says what you're looking at or what the last step
proved. The timing is off too: one real run took 8.2 s and came out as 9.2 s of
video, and under load a 16 s take has played back in 10 s. Then the mp4 goes
into the README, and GitHub shows "View raw" instead of a player.

## What it does

- **Films the real thing, live.** One headless Chrome stays open while
  separate commands drive it. A pointer is drawn and glides between targets,
  because headless Chrome draws none, and each click shows a ring.
- **Keeps true speed.** It records with the CDP screencast and keeps every
  frame's timestamp. The encoder then builds a 30 fps sequence from those
  timestamps and prints video length against wall-clock length for every
  take, so drift can't hide.
- **Cuts a story from one plan file:**
  - a title card;
  - takes with one-line, numbered captions;
  - cards for the moments a camera can't film ("The page reloads.", "The
    window closes.");
  - an end card with your repo link;
  - cross-fades between segments, and eased zooms onto the part of the UI
    that proves each step.
- **Delivers the formats you need:**
  - an H.264 mp4 with faststart and no audio, for a `<video autoplay muted
    loop playsinline>` tag;
  - a poster frame;
  - a GIF sized for a README.
- **Covers editor add-ons too.** A VS Code or Cursor extension can be filmed
  in `code serve-web` in the same browser. The recipe and its traps are in
  [`references/vscode-extension.md`](references/vscode-extension.md): settings
  stored in the browser, closing and reopening a window, and Claude Code in
  the editor's terminals.

## Before / after

The same request, "record a clip of the todo app", without and with the skill.
Both are real runs on [`examples/todo-app`](examples/todo-app/), and the frames
come from the output videos. Before is puppeteer `page.screencast()` straight
to a file. After is [`examples/run-example.sh`](examples/run-example.sh).

Before:

![before](examples/before.png)

After:

![after](examples/after.png)

## How to install

Paste this into Claude Code (or any coding agent):

```text
Install the release-clip skill globally from https://github.com/ussumant/useful-agent-skills and read its README
```

Or with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill release-clip --global --yes
```

It needs node with puppeteer, Chrome, python3 and ffmpeg:

```sh
npm i -g puppeteer            # or npm i puppeteer inside the skill folder
export PUPPETEER_PATH=/path/to/node_modules/puppeteer   # or point at an existing install
brew install ffmpeg           # any ffmpeg with libx264
```

Check it with the self-test, from any folder:

```sh
bash ~/.claude/skills/release-clip/examples/run-example.sh /tmp/clip-test
```

It writes `todos-demo.mp4`, a poster and a GIF, about 19 s in all.

## How to use

Tell the agent what shipped and where the clip will go:

```text
I just released v1.2 with offline sync. Make a 25-second clip showing it working, for the README and my site.
```

The agent:
1. writes the 3–5 beats into a plan;
2. builds a throwaway stage with sample data;
3. records one take per beat and checks each take's speed line;
4. sets trims, captions and zooms;
5. runs `compose.py`, checks the frames, and hands you the mp4, poster and GIF.

To run it by hand:

```sh
node browser.js 1280x800 2 &                 # one headless Chrome on port 9333
node step.js goto http://localhost:3000 '#app'
node record.js takes/A &                     # start filming
node step.js glideto 'button' 'Save' 800 && node step.js clickhere
touch takes/A/STOP                           # stop filming
python3 encode.py takes/A takes/A.mp4        # prints video vs wall-clock length
python3 compose.py plan.json                 # cards, captions, zooms, fades → mp4 + poster + gif
```

The plan's fields are documented in [`plan.example.json`](plan.example.json)
and in `SKILL.md`.

## What's inside

| file | what it does |
|---|---|
| `SKILL.md` | the rules, workflow, commands, QA checklist and the traps that cost a round |
| `browser.js` | keeps one headless Chrome open, with a drawn pointer, a click ring and optional hidden overlays |
| `step.js` | one action per call: `goto`, `type`, `key`, `glide`, `glideto`, `clickhere`, `waitfor`, `drag`, `eval`, `shot` … |
| `record.js` | CDP screencast with a timestamp on every frame |
| `encode.py` | timestamped frames → a true-speed 30 fps mp4 |
| `cards.js` | renders title, dark and end cards and caption strips at the clip's exact size |
| `compose.py` | the cut: trims, captions, eased zooms, cross-fades, poster and GIF |
| `lib.js` | finds puppeteer and Chrome |
| `fonts/` | Pixelify Sans for card titles (SIL Open Font License) |
| `references/vscode-extension.md` | filming a VS Code or Cursor add-on |
| `examples/` | the todo app, its plan and runner, and the before/after pages and PNGs |

## Honest caveats

- **Browser-reachable things only:** web apps, `code serve-web`, and Electron
  apps started with a debugging port. For native apps, use a screen recorder.
- **The drawn pointer is an overlay.** The clicks are real. It's injected only
  into pages opened by `browser.js`.
- **Typed text and clicks run at script speed**, which is faster than a person
  would go. Add `wait` steps where a viewer needs a beat.
- **Zoom keys are set by hand** from a contact sheet. Nothing finds the
  interesting region for you.
- **The card style is opinionated:** a pixel title font, mono body and an
  orange rule. Change it through `theme` in the plan (colours and `font_file`).
- **Some setups need help that's out of frame.** In the VS Code recipe, the
  reopened window can land in a different storage folder. Copying the add-on's
  saved state across is disclosed in the recipe, and should be disclosed in
  your hand-off too.
