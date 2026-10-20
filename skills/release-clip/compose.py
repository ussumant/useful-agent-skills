#!/usr/bin/env python3
"""python3 compose.py PLAN.json — cuts the clip: cards, takes with captions and eased zooms, cross-fades.

Paths in the plan resolve from the plan's folder. Writes plan["out"] (H.264 mp4, faststart, no audio)
and plan["poster"] (a PNG frame at plan["poster_at"] seconds). Shape: see plan.example.json.
"""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
plan_path = os.path.abspath(sys.argv[1]); base = os.path.dirname(plan_path)
plan = json.load(open(plan_path))
W, UH = plan.get('width', 1600), plan.get('ui_height', 1000)
CH = plan.get('caption_height', 120); H = UH + CH
FADE = plan.get('fade', 0.4)
def ffcolor(c):   # ffmpeg wants 0xRRGGBB, not #fff
    c = c.lstrip('#'); return '0x' + (''.join(ch * 2 for ch in c) if len(c) == 3 else c)
PAPER = ffcolor(plan.get('theme', {}).get('paper', '#fff'))
work = os.path.join(base, '.clip-work'); os.makedirs(work, exist_ok=True)
rel = lambda p: p if os.path.isabs(p) else os.path.join(base, p)
ENC = ['-r', '30', '-pix_fmt', 'yuv420p', '-color_range', 'tv', '-c:v', 'libx264', '-crf', '12']

def run(args): subprocess.run(['ffmpeg', '-v', 'error', '-y'] + args, check=True)

def eased(keys, T):
    # keys [(t, value)] in segment seconds → ffmpeg expression in time T, cosine-eased between keys
    e = f'{keys[-1][1]}'
    for (t0, v0), (t1, v1) in reversed(list(zip(keys, keys[1:]))):
        mid = f'{v0}' if v0 == v1 else f'({v0}+({v1}-{v0})*(1-cos(PI*({T}-{t0})/{t1 - t0}))/2)'
        e = f'if(lt({T},{t1}),{mid},{e})'
    return f'if(lt({T},{keys[0][0]}),{keys[0][1]},{e})'

def zoom(keys):
    # keys [[t, zoom, cx, cy]], cx/cy = centre as fractions of the frame; zoompan over a 3x upscale keeps pans smooth
    T = '(on/30)'
    z = eased([(k[0], k[1]) for k in keys], T)
    cx = eased([(k[0], k[2]) for k in keys], T); cy = eased([(k[0], k[3]) for k in keys], T)
    x = f'max(0,min(iw-iw/zoom,({cx})*iw-iw/zoom/2))'; y = f'max(0,min(ih-ih/zoom,({cy})*ih-ih/zoom/2))'
    return f"scale={W*3}:{UH*3}:flags=lanczos,zoompan=z='{z}':x='{x}':y='{y}':d=1:s={W}x{UH}:fps=30"

subprocess.run(['node', os.path.join(HERE, 'cards.js'), plan_path, work], check=True)
segs = []
for i, s in enumerate(plan['segments']):
    dst = os.path.join(work, f'seg-{i}.mp4')
    if 'card' in s:
        secs = s.get('secs', 2.5)
        run(['-loop', '1', '-framerate', '30', '-t', str(secs), '-i', os.path.join(work, f'card-{i}.png'),
             '-vf', 'scale=out_range=tv,format=yuv420p'] + ENC + [dst])
    else:
        take_len = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', rel(s['take'])],
                                        capture_output=True, text=True).stdout)
        t_in = s.get('in', 0); t_out = min(s.get('out', take_len), take_len); secs = t_out - t_in
        caps = s.get('captions', []) if CH > 0 else []
        inputs = ['-ss', str(t_in), '-to', str(t_out), '-i', rel(s['take'])]
        for j, _ in enumerate(caps): inputs += ['-loop', '1', '-i', os.path.join(work, f'cap-{i}-{j}.png')]
        body = zoom(s['zoom']) if s.get('zoom') else f'scale={W}:{UH}:flags=lanczos'
        f = f'[0]setpts=PTS-STARTPTS,{body},pad={W}:{H}:0:0:{PAPER},scale=out_range=tv,format=yuv420p[v0]'
        for j, c in enumerate(caps):
            a = c.get('at', 0); b = caps[j + 1].get('at', 0) if j + 1 < len(caps) else 9999
            f += f";[v{j}][{j+1}]overlay=0:{UH}:enable='between(t,{a},{b})':shortest=1[v{j+1}]"
        run(inputs + ['-filter_complex', f, '-map', f'[v{len(caps)}]'] + ENC + [dst])
    segs.append((dst, secs))

out = rel(plan.get('out', 'demo.mp4'))
inputs = sum([['-i', p] for p, _ in segs], [])
chain, prev, acc = [], '[0]', 0
for i in range(1, len(segs)):
    acc += segs[i - 1][1] - FADE
    chain.append(f'{prev}[{i}]xfade=transition=fade:duration={FADE}:offset={acc:.3f}[x{i}]'); prev = f'[x{i}]'
graph = ['-filter_complex', ';'.join(chain), '-map', prev] if chain else ['-map', '0']
run(inputs + graph + ['-r', '30', '-pix_fmt', 'yuv420p', '-color_range', 'tv', '-colorspace', 'bt709', '-color_primaries', 'bt709',
                      '-color_trc', 'bt709', '-c:v', 'libx264', '-crf', str(plan.get('crf', 23)), '-preset', 'slow', '-movflags', '+faststart', '-an', out])
if plan.get('gif'):   # GitHub's file view won't play an mp4, but a README plays a GIF inline
    gw, gfps = plan.get('gif_width', 800), plan.get('gif_fps', 12)
    run(['-i', out, '-filter_complex', f'fps={gfps},scale={gw}:-2:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle',
         '-loop', '0', rel(plan['gif'])])
if plan.get('poster'):
    run(['-ss', str(plan.get('poster_at', 0.5)), '-i', out, '-frames:v', '1', rel(plan['poster'])])
dur = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', out], capture_output=True, text=True).stdout.strip()
print(f'{out}: {float(dur):.1f}s, {W}x{H}, {os.path.getsize(out) // 1024} KB' + (f"; poster {rel(plan['poster'])}" if plan.get('poster') else '')
      + (f"; gif {os.path.getsize(rel(plan['gif'])) // 1024} KB" if plan.get('gif') else ''))
