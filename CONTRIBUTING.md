# Contributing a skill

Every skill in this repo is a self-contained folder under `skills/<name>/`.
The bar is "used every day"; the checklist below is what "published" means.

## Checklist

- [ ] `SKILL.md` with frontmatter (`name`, `description` that names the
      trigger phrases) and the instructions the agent loads.
- [ ] `README.md` that is problem-first: **Problem → What it does → Before /
      after → How to install → How to use → What's inside → Honest caveats**.
- [ ] **Before / after screenshots, on a general example.** `examples/before.png`
      shows what the agent produces without the skill; `examples/after.png`
      shows the same task with it. Same task, same content, one variable
      changed. The example must be something any developer recognizes (a pull
      request flow, a test run, a cost table), never the author's own project,
      data, or usage numbers. Say in the caption how the images were made
      (a real run, or a rendering of real output with example numbers).
- [ ] Scripts are plain bash, python3 stdlib, or node with the dependency
      named in the README. Nothing phones home.
- [ ] No personal paths outside the skill folder, no references to private
      repos, unpublished pages, or people.
- [ ] A release per skill drop (`vX.Y.0 — <skill>`), so Watch → Releases works.

## Making the screenshots

- Terminal output (hooks, statuslines, CLIs): put the "before" and "after"
  transcripts in `examples/before.txt` and `examples/after.txt`, then
  `python3 tools/terminal-shot/render.py examples/after.txt examples/after.html --title "…" --png /abs/path/examples/after.png`.
  Use the skill's real output format; example numbers are fine when the real
  ones are personal, and the caption must say so.
- Rendered artifacts (diagrams, pages, docs): build the before and after as
  HTML and shoot them with `skills/explainer-diagrams/shoot.mjs` and a plan
  file (see `skills/explainer-diagrams/plan.example.json`).
- Look at both PNGs before committing. Cropped, blurry, or fallback-font
  screenshots do not ship.
