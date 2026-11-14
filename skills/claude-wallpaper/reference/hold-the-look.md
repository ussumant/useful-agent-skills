# Holding the look against other theme mods

A session has one theme, and the last `$.theme.set` wins. Anthropic's `theme-examples` plugin (and any copy of it)
applies its chosen theme at the start of every message, so a theme set only at `session.start` disappears as soon as
the person types. A renamed copy is worse: its backdrop is never drawn, and the window goes blank.

Signs: the wallpaper vanishes right after a message; a dim `<other-plugin>: …` line sits under the message; the
window shows a flat tint with no scene. Plugins saved to the account in the desktop app live in
`~/Library/Application Support/Claude/local-agent-mode-sessions/*/*/rpm/plugin_*/`.

A theme call is an event other mods can hook. This turns away every theme that isn't ours, quietly:

```tsx
import type { ThemeResult } from 'claude-code'

const HELD: ThemeResult = { isDrawn: false, reason: 'This theme holds the chat, so another was not applied' }

on('theme.set', ($, e, next) => {
  const backdrop = e.backdrop

  if (backdrop !== undefined && 'scene' in backdrop && backdrop.scene === NAME) {
    return next(e)
  }

  return { value: HELD }
})

on('theme.clear', () => ({ value: HELD }))
```

Answer with `{ value }`, not `{ deny }`: a deny makes the other mod log a failure on every message. To let the
wallpaper lab through while testing, also pass scenes whose name starts with `wallpaper-lab-`.

Blocking another mod is a product decision. In a personal chat it is fine. In a plugin other people install, ask the
owner first: they may want their own theme to win.
