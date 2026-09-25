// Computed-style dump for landmark selectors.
// node dump.mjs <url> <out.json> <width> <height> <config.json> [side=ref|clone]
// config: { "landmarks": [".hero h1", ...], "map": { ".hero h1": ".my-title" } }  (map applies when side=clone)
import fs from 'node:fs';
import { launch, openPage, revealAll, loadJSON } from './_lib.mjs';
const [url, out, w = 1440, h = 900, cfgPath, side = 'ref'] = process.argv.slice(2);
const cfg = loadJSON(cfgPath); const L = cfg.landmarks || []; const MAP = side === 'clone' ? cfg.map || {} : {};
const P = cfg.props || ['display', 'position', 'font-family', 'font-size', 'font-weight', 'line-height', 'letter-spacing', 'color', 'background-color', 'background-image',
  'border', 'border-radius', 'box-shadow', 'backdrop-filter', 'padding', 'margin', 'gap', 'width', 'height', 'opacity', 'text-shadow', 'transform', 'text-transform', 'text-align', 'filter', 'mix-blend-mode', 'z-index'];
const b = await launch(); const p = await openPage(b, url, w, h);
await revealAll(p); await p.waitForTimeout(1200);
const res = await p.evaluate(([L, P, MAP]) => {
  const probe = document.createElement('div'); document.body.appendChild(probe); const D = getComputedStyle(probe);
  const o = {};
  for (const s of L) {
    const el = document.querySelector(MAP[s] || s); if (!el) { o[s] = null; continue; }
    const r = el.getBoundingClientRect(), cs = getComputedStyle(el), st = {};
    for (const k of P) { const v = cs.getPropertyValue(k); if (v && v !== D.getPropertyValue(k) && !['none', 'normal', 'auto'].includes(v)) st[k] = v; }
    o[s] = { box: [r.x, r.y + scrollY, r.width, r.height].map(Math.round), st };
  }
  o._H = document.documentElement.scrollHeight;
  return o;
}, [L, P, MAP]);
fs.writeFileSync(out, JSON.stringify(res, null, 1));
console.log('dumped', L.length, 'landmarks, page height', res._H);
await b.close();
