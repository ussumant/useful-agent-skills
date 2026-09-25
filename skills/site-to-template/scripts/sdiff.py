#!/usr/bin/env python3
"""Property-level computed-style diff between two dump.mjs outputs.  python3 sdiff.py ref.json clone.json
Ignores width/height/opacity/transform (reveal state) and url() backgrounds (you swapped in your own assets)."""
import json, re, sys
a, b = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
PROPS = ['font-family', 'font-size', 'font-weight', 'line-height', 'letter-spacing', 'color', 'background-color', 'background-image',
         'border', 'border-radius', 'box-shadow', 'text-shadow', 'backdrop-filter', 'padding', 'gap', 'text-transform', 'text-align']
def norm(p, v):
    v = re.sub(r'\s+', ' ', v or '').strip()
    return v.split(',')[0].strip('"\' ') if p == 'font-family' else v
bad = tot = 0
for k, v in a.items():
    if k.startswith('_') or not v: continue
    w = b.get(k)
    if not w: print('MISSING', k); continue
    for p in PROPS:
        x, y = norm(p, v['st'].get(p)), norm(p, w['st'].get(p)); tot += 1
        if p == 'background-image' and 'url(' in x + y: continue
        if x != y:
            bad += 1; print(f'{k:30s} {p:16s} ref={x[:80]}\n{"":47s} me ={y[:80]}')
print(f'\n{tot - bad}/{tot} property checks match')
