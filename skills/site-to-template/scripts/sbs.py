#!/usr/bin/env python3
"""Pair <name>-ref.png / <name>-clone.png into half-size side-by-sides.  python3 sbs.py <dir>   (needs Pillow)"""
import glob, sys
from PIL import Image
d = sys.argv[1] if len(sys.argv) > 1 else 'sec'
for f in sorted(glob.glob(f'{d}/*-ref.png')):
    a = Image.open(f).convert('RGB'); b = Image.open(f.replace('-ref.png', '-clone.png')).convert('RGB')
    c = Image.new('RGB', (a.width + b.width + 20, max(a.height, b.height)), 'white'); c.paste(a, (0, 0)); c.paste(b, (a.width + 20, 0))
    o = f.replace('-ref.png', '-sbs.jpg'); c.resize((c.width // 2, c.height // 2)).save(o, quality=85); print(o)
