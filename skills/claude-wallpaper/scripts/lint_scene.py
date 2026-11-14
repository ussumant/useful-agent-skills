#!/usr/bin/env python3
"""lint_scene.py <scene.svg | scene.ts>: flag what is known to stop the Claude app animating or drawing a backdrop scene.

Facts (Claude desktop, engine 2.1.325, 14 Nov 2026): shape-rendering anywhere freezes a scene (tested);
any media query except prefers-reduced-motion freezes it (reported by stillgbx/synthwave-claude, not isolated by us);
raster pictures draw nothing; a scene may be at most 131072 characters.
Exit 0 when nothing known would freeze or hide the scene, 1 otherwise.
"""
import json
import re
import sys

LIMIT = 131072


def load(path):
    text = open(path, encoding="utf-8").read()
    if path.endswith(".ts"):
        m = re.search(r"export const SCENE\s*=\s*", text)
        if not m:
            sys.exit("no 'export const SCENE = ' found in " + path)
        text, _ = json.JSONDecoder().raw_decode(text, m.end())
    return text


def lint(svg):
    fatal, other = [], []
    if "shape-rendering" in svg:
        fatal.append("FREEZE (tested): shape-rendering found; the app draws the scene still. Remove it everywhere (rule or attribute).")
    for m in re.finditer(r"@media\s*([^{]*)\{", svg):
        cond = m.group(1).strip()
        if "prefers-reduced-motion" not in cond:
            fatal.append(f"FREEZE (reported): media query ({cond}); the app draws the scene still. Only prefers-reduced-motion is safe.")
    if "<image" in svg or "data:image" in svg:
        fatal.append("NOT DRAWN (tested): raster picture (<image or data:image); pictures draw nothing in the backdrop. Use vector shapes.")
    if len(svg) > LIMIT:
        fatal.append(f"REFUSED: {len(svg)} characters, the limit is {LIMIT}")
    if "<filter" in svg:
        other.append("RISK: <filter> found; a scene with a filter and mix-blend-mode stayed still once (never isolated).")
    if "mix-blend-mode" in svg:
        other.append("RISK: mix-blend-mode found; see the filter note (never isolated).")
    if ' style="' in svg:
        other.append('RISK: style="..." attribute found; the app may drop inline styles. Put styles in the <style> sheet.')
    root = re.search(r"<svg\b[^>]*>", svg)
    tag = root.group(0) if root else ""
    if "viewBox" not in tag:
        other.append("WARN: root <svg> has no viewBox.")
    if 'preserveAspectRatio="xMidYMid slice"' not in tag:
        other.append('WARN: root <svg> lacks preserveAspectRatio="xMidYMid slice"; the scene may not fill the window.')
    if "@keyframes" not in svg:
        other.append("NOTE: no @keyframes, the scene is static")
    if "prefers-reduced-motion" not in svg:
        other.append("NOTE: no reduced-motion rule")
    return fatal, other


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    svg = load(sys.argv[1])
    fatal, other = lint(svg)
    for line in fatal + other:
        print(line)
    if fatal:
        print("FAIL: the app would not animate or draw this scene")
        return 1
    print(f"OK: nothing known to freeze this scene ({len(svg)} characters)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
