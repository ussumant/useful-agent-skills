# useful-agent-skills

Practical skills for Claude Code and other coding agents, published as they
get battle-tested in daily use. If it's in the table, I use it every day.

⭐ **Star** the repo and **Watch → Custom → Releases** — every new skill
ships as a release, so you get notified when a new one drops.

## Skills

| Skill | Problem it solves |
|---|---|
| [fable-low-power](skills/fable-low-power/) | Your frontier-model quota burns down on greps and builds a cheaper model could do. This watches your live 5h/7d limits and flips Claude Code into a frontier-judges / cheap-executes profile before you hit the wall — and tracks the burn so you can see the savings. |

## How to install a skill

The easiest way is to paste this into Claude Code or your favorite coding
agent:

```text
Install the fable-low-power skill globally from https://github.com/ussumant/useful-agent-skills and wire it up per its README
```

You can also install with `npx`:

```sh
npx skills add ussumant/useful-agent-skills --skill fable-low-power --global --yes
```

Or fully manually:

```sh
git clone https://github.com/ussumant/useful-agent-skills.git
cp -r useful-agent-skills/skills/<name> ~/.claude/skills/<name>
```

Some skills need a line or two of `settings.json` wiring (hooks, statusline)
— each skill's own `README.md` has the exact snippet.

## What's inside a skill

Every skill is a self-contained folder: `SKILL.md` (the instructions your
agent loads) plus any scripts it needs. Plain bash + python3 stdlib —
nothing to install, nothing phones home.

## License

MIT
