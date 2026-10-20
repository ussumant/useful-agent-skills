#!/usr/bin/env node
// node cards.js PLAN.json WORKDIR — renders the plan's cards and caption strips to PNGs at the clip's exact size:
//   WORKDIR/card-<segment>.png and WORKDIR/cap-<segment>-<n>.png. compose.py calls this; run it alone to check the look.
const fs = require('node:fs'), path = require('node:path');
const { loadPuppeteer, chromePath } = require('./lib');
const puppeteer = loadPuppeteer();
const planPath = path.resolve(process.argv[2]); const work = path.resolve(process.argv[3]);
const plan = JSON.parse(fs.readFileSync(planPath, 'utf8'));
const W = plan.width || 1600, UH = plan.ui_height || 1000, CH = plan.caption_height ?? 120, H = UH + CH;
const th = Object.assign({ font_file: 'fonts/PixelifySans[wght].ttf', display: 'Pixelify Sans', paper: '#fff', ink: '#000', text: '#3f3f3f',
  muted: '#767676', accent: '#d66b2f', dark: '#101722', dark_text: '#b9c0cc', line: '#d7d7d7',
  mono: 'ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, monospace' }, plan.theme || {});
fs.mkdirSync(work, { recursive: true });
let font = '';
for (const base of [path.dirname(planPath), __dirname]) {
  const f = path.resolve(base, th.font_file || '');
  if (th.font_file && fs.existsSync(f)) { fs.copyFileSync(f, path.join(work, 'display' + path.extname(f))); font = 'display' + path.extname(f); break; }
}
const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;');
const css = `${font ? `@font-face{font-family:"${th.display}";src:url("${font}");font-weight:100 900}` : ''}
*{margin:0;box-sizing:border-box} body{background:${th.paper};font-family:${th.mono};font-variant-ligatures:none}
.card{width:${W}px;height:${H}px;display:flex;flex-direction:column;justify-content:center;padding:0 ${Math.round(W * .106)}px;background:${th.paper}}
.card.dark{background:${th.dark}}
h1{font-family:"${th.display}",${th.mono};font-weight:500;color:${th.ink};line-height:1.05;font-feature-settings:"liga" 0}
.big h1{font-size:${Math.round(W * .07)}px} h1{font-size:${Math.round(W * .0475)}px} .dark h1{color:#fff}
.lead{font-size:${Math.round(W * .0194)}px;line-height:1.5;margin-top:${Math.round(W * .0275)}px;color:${th.text};max-width:${Math.round(W * .74)}px}
.dark .lead{color:${th.dark_text}} .small{font-size:${Math.round(W * .015)}px;margin-top:${Math.round(W * .016)}px;color:${th.muted}}
.rule{width:${Math.round(W * .045)}px;height:5px;background:${th.accent};margin-bottom:${Math.round(W * .029)}px}
.cap{width:${W}px;height:${CH}px;display:flex;align-items:center;gap:${Math.round(W * .0175)}px;padding:0 ${Math.round(W * .04)}px;background:${th.paper};border-top:1px solid ${th.line}}
.cap .n{font-size:${Math.round(CH * .217)}px;color:${th.accent};font-weight:600} .cap .t{font-size:${Math.round(CH * .242)}px;color:${th.ink};line-height:1.35}`;
const jobs = []; let num = 0;
plan.segments.forEach((s, i) => {
  if (s.card) {
    const c = s.card, big = c.big ?? i === 0;
    jobs.push({ file: `card-${i}.png`, w: W, h: H, html: `<section class="card${c.dark ? ' dark' : ''}${big ? ' big' : ''}">${c.dark ? '' : '<div class="rule"></div>'}<h1>${esc(c.title)}</h1>${c.lead ? `<p class="lead">${esc(c.lead)}</p>` : ''}${c.small ? `<p class="small">${esc(c.small)}</p>` : ''}</section>` });
  }
  if (s.take && CH > 0) (s.captions || []).forEach((cap, j) => {
    num++; const n = plan.number_captions === false ? '' : `<span class="n">${String(num).padStart(2, '0')}</span>`;
    jobs.push({ file: `cap-${i}-${j}.png`, w: W, h: CH, html: `<div class="cap">${n}<span class="t">${esc(cap.text)}</span></div>` });
  });
});
(async () => {
  const b = await puppeteer.launch({ headless: true, executablePath: chromePath(puppeteer) });
  const p = await b.newPage();
  for (const j of jobs) {
    fs.writeFileSync(path.join(work, 'card.html'), `<!doctype html><html><head><meta charset="utf-8"><style>${css}</style></head><body>${j.html}</body></html>`);
    await p.setViewport({ width: j.w, height: j.h, deviceScaleFactor: 1 });
    await p.goto('file://' + path.join(work, 'card.html')); await p.evaluate(() => document.fonts.ready);
    const [ok, over] = await p.evaluate((d) => [!d || !document.querySelector('h1') || document.fonts.check(`40px "${d}"`), document.body.scrollWidth > innerWidth || document.body.scrollHeight > innerHeight], font ? th.display : '');
    await p.screenshot({ path: path.join(work, j.file), clip: { x: 0, y: 0, width: j.w, height: j.h } });
    console.log(j.file, ok ? 'font ok' : 'FONT FALLBACK', over ? 'OVERFLOWS' : 'fits');
  }
  await b.close();
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
