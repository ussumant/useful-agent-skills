#!/usr/bin/env bash
# codex-dispatch usage report — runs, tokens, heaviest working dirs for one local day.
# Usage: usage.sh [YYYY-MM-DD] [--brief]
#
# Reads codex's own per-session JSONL logs (codex writes total_token_usage
# per turn) — no network call, no extra billing. Default location is the
# Codex CLI's standard session directory; override with CODEX_DISPATCH_SESSIONS_DIR
# if your install writes elsewhere (check `codex --help` / your CLI version's docs).
set -euo pipefail
SESSIONS_DIR="${CODEX_DISPATCH_SESSIONS_DIR:-$HOME/.codex/sessions}"
DAY="$(date +%Y-%m-%d)"
BRIEF=""
for arg in "$@"; do
  case "$arg" in
    --brief) BRIEF="--brief" ;;
    *) DAY="$arg" ;;
  esac
done
[[ "$DAY" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || {
  echo "usage: $0 [YYYY-MM-DD] [--brief]" >&2
  exit 2
}

python3 - "$DAY" "$BRIEF" "$SESSIONS_DIR" <<'PY'
import json, glob, os, re, sys, collections, datetime
day, brief, sessions_dir = sys.argv[1], sys.argv[2], sys.argv[3]
y, m, d = day.split('-')
files = glob.glob(os.path.join(os.path.expanduser(sessions_dir), y, m, d, '*.jsonl'))
rows = []
for f in files:
    cwd = model = None
    last = None
    t0 = t1 = None
    for line in open(f, errors='ignore'):
        if cwd is None:
            mm = re.search(r'"cwd":"([^"]+)"', line)
            cwd = mm.group(1) if mm else None
        if model is None:
            mm = re.search(r'"model":"([^"]+)"', line)
            model = mm.group(1) if mm else None
        mm = re.search(r'"timestamp":"([^"]+)"', line)
        if mm:
            t1 = mm.group(1)
            t0 = t0 or t1
        if '"total_token_usage"' in line:
            last = line
    if not last:
        continue
    u = json.loads(re.search(r'"total_token_usage":(\{[^}]*\})', last).group(1))
    try:
        mins = (datetime.datetime.fromisoformat(t1.replace('Z', '+00:00'))
                - datetime.datetime.fromisoformat(t0.replace('Z', '+00:00'))).total_seconds() / 60
    except Exception:
        mins = 0
    rows.append(dict(
        cwd=(cwd or '?').replace(os.path.expanduser('~'), '~'),
        model=model or '?',
        inp=u.get('input_tokens', 0), cached=u.get('cached_input_tokens', 0),
        out=u.get('output_tokens', 0), mins=mins,
    ))
if not rows:
    print(f'codex usage {day}: no runs found under {sessions_dir}')
    sys.exit(0)
I = sum(r['inp'] for r in rows)
C = sum(r['cached'] for r in rows)
O = sum(r['out'] for r in rows)
W = sum(r['mins'] for r in rows)
models = collections.Counter(r['model'] for r in rows)
cache_pct = f"{C / I * 100:.0f}%" if I else "n/a"
print(f"codex usage {day}: {len(rows)} runs · input {I/1e6:.1f}M ({cache_pct} cached) "
      f"· output {O/1e3:.0f}k · wall {W/60:.1f}h · models {dict(models)}")
if brief == '--brief':
    sys.exit(0)
by = collections.defaultdict(lambda: [0, 0, 0, 0.0])
for r in rows:
    b = by[r['cwd'][-48:]]
    b[0] += 1; b[1] += r['inp']; b[2] += r['out']; b[3] += r['mins']
print('  runs | input | output | wall | cwd')
for k, v in sorted(by.items(), key=lambda x: -x[1][1])[:10]:
    print(f"  {v[0]:4d} | {v[1]/1e6:6.1f}M | {v[2]/1e3:5.0f}k | {v[3]/60:4.1f}h | {k}")
PY
