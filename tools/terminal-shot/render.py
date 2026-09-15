#!/usr/bin/env python3
"""render.py — fill terminal.html with a lightweight-marked-up transcript.

Usage:
  python3 render.py <input.txt> <out.html> --title "Terminal" [--png <abs path>]

Markers in the input text:
  "> "        -> whole line wrapped class="user" (prefix kept)
  "# "        -> whole line wrapped class="dim" (prefix stripped)
  {green}..{/}, {yellow}..{/}, {blue}..{/}, {dim}..{/} -> inline spans

With --png, also writes a plan.json next to the output html and runs
shoot.mjs against it (one #shot1 capture at 1300x900, deviceScaleFactor 2).
"""
import argparse
import html
import json
import re
import subprocess
import sys
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
TEMPLATE = TOOL_DIR / "terminal.html"
import os
_CANDIDATES = [
    Path(os.environ["SHOOT_MJS"]) if os.environ.get("SHOOT_MJS") else None,
    TOOL_DIR.parent.parent / "skills" / "explainer-diagrams" / "shoot.mjs",   # repo layout
    Path.home() / ".claude" / "skills" / "explainer-diagrams" / "shoot.mjs",  # installed-skill layout
]
SHOOT = next((c for c in _CANDIDATES if c and c.exists()), _CANDIDATES[1])

MARKER_RE = re.compile(r"\{(dim|green|yellow|blue)\}(.*?)\{/\}")


def render_line(line: str) -> str:
    css_class = None
    content = line
    if line.startswith("# "):
        css_class, content = "dim", line[2:]
    elif line.startswith("> "):
        css_class, content = "user", line

    escaped = html.escape(content)
    escaped = MARKER_RE.sub(lambda m: f'<span class="{m.group(1)}">{m.group(2)}</span>', escaped)

    if css_class:
        return f'<span class="{css_class}">{escaped}</span>'
    return escaped


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--title", default="Terminal")
    ap.add_argument("--png")
    args = ap.parse_args()

    lines = Path(args.input).read_text().splitlines()
    body = "\n".join(render_line(l) for l in lines)

    out_html = TEMPLATE.read_text().replace("{{TITLE}}", html.escape(args.title)).replace("{{BODY}}", body)
    out_path = Path(args.output).resolve()
    out_path.write_text(out_html)
    print(f"wrote {out_path}")

    if args.png:
        png_path = Path(args.png).resolve()
        plan = {
            "path": str(out_path),
            "viewport": {"width": 1300, "height": 900, "deviceScaleFactor": 2},
            "steps": [
                {"type": "wait", "ms": 150},
                {"type": "shot", "selector": "#shot1", "path": str(png_path)},
            ],
        }
        plan_path = out_path.with_suffix(".plan.json")
        plan_path.write_text(json.dumps(plan, indent=2))
        print(f"wrote {plan_path}")

        result = subprocess.run(["node", str(SHOOT), str(plan_path)], capture_output=True, text=True)
        print(result.stdout)
        if result.returncode != 0:
            print(result.stderr, file=sys.stderr)
            sys.exit(result.returncode)


if __name__ == "__main__":
    main()
