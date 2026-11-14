"""moved.py <a.png> <b.png> [--probe]: did the Claude window's backdrop move between two photos taken about a second apart?

Run:  uv run -q --with pillow --with numpy python -I moved.py <a.png> <b.png> [--probe]

Verdicts: MOVING or STILL. With --probe, NO PROBE when the yellow probe square is missing from either photo: the scene
was not showing (the window was between two themes, or another mod's theme stood), so it is not a result.
It counts changed pixels in the two side gutters (fractions of the image size), where the conversation does not draw.
MOVING means more than 400 changed gutter pixels. With --probe it also finds the yellow probe square
(the reference/scenes/probe.svg square) in each photo, prints its x-range, and counts a shift of more than 3 px as MOVING.
"""
import sys
from PIL import Image, ImageChops
import numpy as np

args = [x for x in sys.argv[1:] if not x.startswith('--')]
probe = '--probe' in sys.argv[1:]
if len(args) != 2:
    sys.exit(__doc__)
a = Image.open(args[0]).convert('RGB')
b = Image.open(args[1]).convert('RGB')


def yellow(im):
    arr = np.asarray(im).astype(int)
    m = (arr[..., 0] > 180) & (arr[..., 1] > 200) & (arr[..., 2] < 170)
    ys, xs = np.nonzero(m)
    return (int(m.sum()), int(xs.min()), int(xs.max())) if m.sum() else (0, None, None)


ya, yb = yellow(a), yellow(b)
d = np.asarray(ImageChops.difference(a, b)).astype(int).sum(2)
H, Wd = d.shape
gut = int((d[int(H * .06):int(H * .9), int(Wd * .15):int(Wd * .345)] > 24).sum()
          + (d[int(H * .06):int(H * .9), int(Wd * .80):int(Wd * .995)] > 24).sum())
# a patch of the right gutter in photo b: its mean colour, printed so you can see which ground was showing
y0, x0 = int(H * .55), int(Wd * .82)
col = np.asarray(b).astype(int)[y0:y0 + max(1, int(H * .07)), x0:x0 + max(1, int(Wd * .06))].reshape(-1, 3).mean(0).round().astype(int).tolist()
# the real probe is over a thousand pixels; a handful of yellow-ish pixels is text or noise, not the probe
in_a, in_b = ya[0] >= 20, yb[0] >= 20

if gut > 400 or (probe and in_a and in_b and abs(ya[1] - yb[1]) > 3):
    verdict = 'MOVING'
elif probe and not (in_a and in_b):
    # a photo can catch the window between two themes, or another mod's theme: that is not a result
    verdict = 'NO PROBE (the scene is not showing in both photos: not a valid test, shoot again)'
elif probe:
    verdict = 'STILL'
else:
    verdict = 'STILL (nothing moved; open the photo to check it shows your scene)'
out = f'{verdict} | gutter changed px={gut} | gutter colour={col}'
if probe:
    out += f' | probe a={ya} b={yb}'
print(out)
