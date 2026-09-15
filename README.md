# useful-agent-skills

Skills for Claude Code and other coding agents that I use every day,
published only after they have survived real work. Every skill ships with a
**before / after** so you can see what it changes before you install anything.

⭐ **Star** the repo · **Watch → Custom → Releases** to get one notification per new skill.

## Skills

### explainer-diagrams

"Make a diagram" gets you a generic flowchart or a table with colored borders,
and every one looks different. This gives the agent one visual grammar, seven
proven scene shapes with finished examples, and a harness that shoots each
diagram to a font-verified PNG. Explanations come out as pictures that read at
a glance and match each other.

| before | after |
|---|---|
| ![before](skills/explainer-diagrams/examples/before.png) | ![after](skills/explainer-diagrams/examples/after.png) |

[Read more →](skills/explainer-diagrams/)

### fable-low-power

Your frontier-model quota burns down on greps, builds, and drafts a cheaper
model could do, and the first warning is the lockout. This watches your live
5-hour and 7-day limits, flips Claude Code into a frontier-judges /
cheap-executes profile before you hit the wall, and tracks the burn so you can
see the savings.

| before | after |
|---|---|
| ![before](skills/fable-low-power/examples/before.png) | ![after](skills/fable-low-power/examples/after.png) |

[Read more →](skills/fable-low-power/)

## Install

Paste into Claude Code or any coding agent:

```text
Install the <skill-name> skill globally from https://github.com/ussumant/useful-agent-skills and read its README
```

With `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill <skill-name> --global --yes
```

By hand:

```sh
git clone https://github.com/ussumant/useful-agent-skills.git
cp -r useful-agent-skills/skills/<skill-name> ~/.claude/skills/<skill-name>
```

A few skills need a line of `settings.json` wiring (a hook or a statusline);
the skill's own README has the exact snippet.

## What's inside a skill

One self-contained folder: `SKILL.md` (what the agent loads), the scripts it
needs, and `examples/before.png` + `after.png` on a general task. Plain bash,
python3 stdlib, or node with the dependency named. Nothing phones home.

Adding one? The bar is in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
