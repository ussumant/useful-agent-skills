#!/usr/bin/env python3
"""Box diff between two geo.mjs outputs.  python3 cmp.py ref.json clone.json [tolerance_px=2]"""
import json, sys
a, b = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
tol = int(sys.argv[3]) if len(sys.argv) > 3 else 2
print(f"page height  ref {a['_H']}  clone {b['_H']}  {'OK' if abs(a['_H'] - b['_H']) <= tol else 'OFF'}")
off = 0; n = 0
for k, v in a.items():
    if k == '_H' or v is None: continue
    n += 1; w = b.get(k)
    if w is None: print(f"  MISSING {k}"); off += 1; continue
    d = [w[i] - v[i] for i in range(4)]; bad = max(map(abs, d)) > tol; off += bad
    print(f"  {'OFF' if bad else 'OK '} {k:32s} ref {v}  clone {w}  diff {d}")
print(f"within ±{tol}px: {n - off}/{n}")
