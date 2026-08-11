# everyday-claude-skills

Practical Claude Code skills, published as they get battle-tested in daily
use. Each skill is a self-contained folder you drop into `~/.claude/skills/`.

⭐ **Star** the repo and **Watch → Custom → Releases** — every new skill ships
as a release, so you get notified when a new one drops.

## Skills

| Skill | What it does |
|---|---|
| [fable-low-power](skills/fable-low-power/) | Auto-detects when your Anthropic usage limits run low and flips Claude Code into a token-saving profile — the frontier model judges, cheaper models execute. Tracks frontier-model burn per session so you can see the savings. Zero credentials; runs off the statusline payload. |

## Install pattern

Every skill follows the same shape:

```bash
git clone https://github.com/ussumant/everyday-claude-skills.git
cp -r everyday-claude-skills/skills/<name> ~/.claude/skills/<name>
```

Then follow the skill's own `README.md` for any settings.json wiring
(statusline, hooks). Skills are plain bash + python3 stdlib — nothing to
install, nothing phones home.

## Why one repo

Skills land here as they prove themselves in real daily work — not as a
dump of everything I try. If it's in the table, I use it.
