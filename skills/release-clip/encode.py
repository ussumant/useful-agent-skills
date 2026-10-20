#!/usr/bin/env python3
"""python3 encode.py TAKE_DIR OUT.mp4 — timestamped screencast frames → a true-speed 30 fps clip.

For each output frame at k/30 s it links the newest screencast frame at or before that moment, so the
gaps between frames keep their real length. (ffconcat `duration` lines don't: images under 40 ms get
stretched, and a 12 s take came out 13.9 s.) Prints video vs wall-clock length; they should match.
"""
import json, os, shutil, subprocess, sys

d, out = os.path.abspath(sys.argv[1]), sys.argv[2]
m = json.load(open(os.path.join(d, 'frames.json')))
fr = m['frames']
if not fr: sys.exit('no frames: did the page change while recording?')
t0 = fr[0]['t']; n = max(1, int((m['end'] - t0) * 30))
seq = os.path.join(d, 'seq'); shutil.rmtree(seq, ignore_errors=True); os.makedirs(seq)
j = 0
for k in range(n):
    while j + 1 < len(fr) and fr[j + 1]['t'] - t0 <= k / 30: j += 1
    os.symlink(os.path.join(d, fr[j]['file']), os.path.join(seq, f'{k:05d}.jpg'))
subprocess.run(['ffmpeg', '-v', 'error', '-y', '-framerate', '30', '-i', os.path.join(seq, '%05d.jpg'),
                '-vf', 'scale=trunc(iw/2)*2:trunc(ih/2)*2:out_range=tv,format=yuv420p', '-color_range', 'tv',
                '-c:v', 'libx264', '-crf', '14', '-preset', 'medium', out], check=True)
dur = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', out],
                           capture_output=True, text=True).stdout)
print(f"{out}: {dur:.2f}s video, {m['end'] - t0:.2f}s wall clock, {len(fr)} frames")
