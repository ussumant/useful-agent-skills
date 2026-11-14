#!/usr/bin/env python3
"""make_kite.py <out dir>: write kite.svg (animated dusk scene with a swaying kite) and kite-frozen.svg
(the same text with shape-rendering added to the kite group: the one-variable "before" case)."""
import os
import sys

CSS = """
.c1{animation:d1 140s linear infinite alternate}
.c2{animation:d2 190s linear infinite alternate}
.c3{animation:d3 110s linear infinite alternate}
@keyframes d1{to{transform:translate(260px,0px)}}
@keyframes d2{to{transform:translate(-300px,0px)}}
@keyframes d3{to{transform:translate(200px,0px)}}
.kite{animation:sway 3s ease-in-out infinite alternate;transform-box:view-box;transform-origin:2260px 380px}
@keyframes sway{from{transform:translate(0px,0px) rotate(-4deg)}to{transform:translate(70px,-40px) rotate(4deg)}}
.tail{animation:flick 1.5s ease-in-out infinite alternate;transform-box:view-box;transform-origin:2260px 455px}
@keyframes flick{from{transform:rotate(-6deg)}to{transform:rotate(6deg)}}
@media (prefers-reduced-motion: reduce){*{animation:none!important}}
""".strip()


def cloud(cls, x, y, s, op):
    parts = [(0, 0, 150, 48), (-90, 14, 100, 36), (95, 16, 110, 38), (20, -28, 90, 38)]
    ell = "".join(f'<ellipse cx="{x + dx * s:.0f}" cy="{y + dy * s:.0f}" rx="{rx * s:.0f}" ry="{ry * s:.0f}"/>' for dx, dy, rx, ry in parts)
    return f'<g class="{cls}" fill="#f6e3dc" opacity="{op}">{ell}</g>'


def build(frozen=False):
    kite_attr = ' shape-rendering="crispEdges"' if frozen else ""
    cx, cy = 2260, 380
    top, right, bottom, left = (cx, cy - 75), (cx + 55, cy - 10), (cx, cy + 75), (cx - 55, cy - 10)
    pts = lambda *p: " ".join(f"{x},{y}" for x, y in p)
    # tail: curved line from the bottom tip with three bows
    tail_path = f"M{cx},{cy + 75} C{cx - 40},{cy + 130} {cx + 40},{cy + 180} {cx},{cy + 240}"
    bows = "".join(
        f'<polygon points="{pts((bx - 14, by - 9), (bx, by), (bx - 14, by + 9))}" fill="#ffd1a3"/>'
        f'<polygon points="{pts((bx + 14, by - 9), (bx, by), (bx + 14, by + 9))}" fill="#ff9a8b"/>'
        for bx, by in [(cx - 22, cy + 120), (cx + 20, cy + 165), (cx - 4, cy + 215)])
    kite = (
        f'<g class="kite"{kite_attr}>'
        f'<g class="tail"><path d="{tail_path}" fill="none" stroke="#f6e3dc" stroke-width="3"/>{bows}</g>'
        f'<polygon points="{pts(top, right, (cx, cy - 10), left)}" fill="#ff8a65"/>'
        f'<polygon points="{pts(right, bottom, (cx, cy - 10))}" fill="#e0533d"/>'
        f'<polygon points="{pts(left, bottom, (cx, cy - 10))}" fill="#ffc27a"/>'
        f'<polygon points="{pts(top, (cx, cy - 10), left)}" fill="#ffb199"/>'
        f'<path d="M{cx},{cy - 75}V{cy + 75}M{cx - 55},{cy - 10}H{cx + 55}" stroke="#5a2a3a" stroke-width="4" fill="none"/>'
        f'</g>')
    hills_far = "M0,1330 C300,1240 560,1260 860,1320 C1160,1380 1420,1230 1740,1250 C2050,1270 2300,1340 2560,1290 V1600 H0Z"
    hills_near = "M0,1450 C340,1380 640,1400 980,1450 C1320,1500 1600,1390 1940,1410 C2240,1430 2420,1470 2560,1440 V1600 H0Z"
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2560 1600" preserveAspectRatio="xMidYMid slice">\n'
        f"<style>\n{CSS}\n</style>\n"
        '<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="#1b2a5e"/><stop offset=".55" stop-color="#4b4a8f"/>'
        '<stop offset=".85" stop-color="#d98a8f"/><stop offset="1" stop-color="#ffc08f"/></linearGradient></defs>\n'
        '<rect width="2560" height="1600" fill="url(#sky)"/>\n'
        f'{cloud("c1", 520, 330, 1.0, 0.55)}\n{cloud("c2", 1500, 560, 1.3, 0.45)}\n{cloud("c3", 900, 900, 0.9, 0.4)}\n'
        f'<path d="{hills_far}" fill="#2a2850"/>\n<path d="{hills_near}" fill="#171933"/>\n'
        f"{kite}\n</svg>\n")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, frozen in (("kite.svg", False), ("kite-frozen.svg", True)):
        with open(os.path.join(out, name), "w", encoding="utf-8") as f:
            f.write(build(frozen))
        print("wrote", os.path.join(out, name))


if __name__ == "__main__":
    main()
