# Filming a VS Code or Cursor add-on

Cursor is VS Code underneath, so an add-on behaves the same in `code serve-web`.
That runs the editor in the headless browser, where `record.js` and `step.js`
can reach it.

## Stage
```sh
D=$HOME/clip-stage            # throwaway; log it in cleanup-paths.txt
mkdir -p "$D/app" "$D/bin" "$D/vscode-data/extensions" "$D/chrome-profile"
# install the add-on: unpack the .vsix's extension/ folder, dotfiles too
mkdir -p "$D/vscode-data/extensions/<publisher>.<name>-<version>" && cd "$_" \
  && unzip -q /path/to/addon.vsix 'extension/*' && mv extension/* . && mv extension/.[!.]* . 2>/dev/null; rmdir extension
```
Start the server with a clean environment. `env -i` keeps your shell's variables
out of the editor's terminals; Claude Code's `CLAUDE_CODE_CHILD_SESSION` in
particular turns off transcripts and session registration:
```sh
cd "$D" && env -i HOME="$HOME" USER="$USER" PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin" \
  LANG=en_US.UTF-8 SHELL=/bin/zsh TMPDIR="$TMPDIR" \
  "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" serve-web --host 127.0.0.1 --port 8123 \
  --connection-token clip --accept-server-license-terms --server-data-dir "$D/vscode-data" --disable-telemetry > "$D/server.log" 2>&1
```
Run it in the background, wait for `available at` in `server.log`, then:
```sh
CLIP_HIDE='.terminal-resize-overlay' CLIP_PROFILE="$D/chrome-profile" node browser.js 1280x800 2   # background
node step.js goto "http://127.0.0.1:8123/?tkn=clip&folder=$D/app" .monaco-workbench
```

## Settings live in the browser
The server's `data/User/settings.json` is ignored, because VS Code web keeps
user settings in the browser's IndexedDB. Paste them in instead:
`key F1` → `type 'Preferences: Open User Settings (JSON)'` → `key Enter` →
`key Meta+a Backspace` → `paste settings.json` → `key Meta+s`. Then check that
it's valid JSON, because auto-closing brackets can add a stray `}`. Settings
worth having:
`security.workspace.trust.enabled: false` (no Restricted Mode banner),
`workbench.startupEditor: none`, `workbench.tips.enabled: false`,
`chat.disableAIFeatures: true`, `extensions.ignoreRecommendations: true`,
`terminal.integrated.gpuAcceleration: off`, `terminal.integrated.fontSize: 14`,
`terminal.integrated.enablePersistentSessions: false`, a plain zsh profile
(`args: ["-f"]`, `PS1: "%1~ %# "`), and `terminal.integrated.env.osx.PATH`
pointing at `$D/bin` first.

## Layout
Run `View: Toggle Maximized Panel` for a full-height terminal. Find splitters
with `eval "[...document.querySelectorAll('.monaco-sash.vertical')].map(e=>e.getBoundingClientRect().x)"`
and `drag` them: the sidebar narrower, the terminal tab list wider so the titles
fit. Read tab positions from `.terminal-tabs-entry`, and toast buttons from
`.notification-toast .monaco-button`.

## Close and reopen the window
Closing = killing the server's process tree. Send SIGHUP to shells and
`claude`, which is what a closing window sends. Match the root on its full app
path, so the killer never matches its own command line:
```python
roots = [p for p, (pp, c) in procs.items() if c.startswith('/Applications/Visual Studio Code.app') and 'serve-web' in c and '--port 8123' in c]
```
Reopening = start the server again, then `goto` the same URL. **Gotcha:** the
reopened window can land on a different workspace storage folder (`<id>-1`
instead of `<id>`). An add-on that saves per-workspace state then finds nothing.
Copy its saved file into every `vscode-data/data/User/workspaceStorage/*/<publisher.name>/`
before reopening, and say so in the hand-off. Only a real-editor run proves the
real editor doesn't do this.

## Claude Code in the terminals
Put a wrapper first on the terminal PATH:
```sh
#!/bin/sh
export CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL=1   # else it installs its VS Code extension, which steals focus
exec /path/to/real/claude --setting-sources project,local --model haiku "$@"   # no personal status line or hooks
```
Don't use `--bare`: it skips the keychain, so login fails. Give each session a
short prompt that says "Don't edit any files." Cleanup:
`~/.claude/projects/<stage path with / → ->`, `~/.claude/session-env/<session ids>`,
and `~/.vscode/cli/serve-web*` (about 600 MB).
