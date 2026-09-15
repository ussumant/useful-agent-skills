#!/usr/bin/env python3
"""detach.py <RESULTS> -- <cmd…>  — run a command fully detached from the calling harness.

Why: an agent harness that shells out via a "Bash tool" often hard-caps a
foreground call at a fixed wall-clock limit and SIGTERMs the whole process
tree when it hits — a long `codex review` / `codex exec` run in the
foreground is how you lose the run and the tokens it spent. A harness
restart/resume can also kill in-process teammates and plain `nohup`'d
children. start_new_session=True puts the child in its own session, so
neither the timeout kill nor a parent-session restart reaches it.

  <cmd…> as several words  → each word shell-quoted (safe for paths with spaces)
  <cmd…> as ONE word       → handed to bash -c verbatim (pipes, redirects, && allowed)
  stdout + stderr          → <RESULTS>.log (appended)
  on exit                  → `rc=<code>` written to <RESULTS>  (a stale RESULTS is removed first)

Poll with a log-tail / file-watch loop on `^rc=` in RESULTS — never pgrep
(the dispatched process's name usually won't match your command string).
Canonical entry: dispatch.sh detach <RESULTS> -- <cmd…>
"""
import os
import shlex
import subprocess
import sys

USAGE = "usage: detach.py <RESULTS> -- <cmd…>"


def main(argv):
    if len(argv) < 4 or argv[2] != "--" or argv[1] in ("-h", "--help"):
        print(USAGE, file=sys.stderr)
        return 2
    results = os.path.abspath(argv[1])
    cmd = argv[3:]
    log = results + ".log"
    parent = os.path.dirname(results)
    if parent:
        os.makedirs(parent, exist_ok=True)
    try:
        os.remove(results)          # a stale rc= from a previous run must never read as this run's
    except FileNotFoundError:
        pass
    body = cmd[0] if len(cmd) == 1 else " ".join(shlex.quote(c) for c in cmd)
    script = f"( {body} ) >>{shlex.quote(log)} 2>&1; echo rc=$? > {shlex.quote(results)}"
    proc = subprocess.Popen(
        ["bash", "-c", script],
        start_new_session=True,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        close_fds=True,
    )
    print(f"DETACHED pid={proc.pid} results={results} log={log}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
