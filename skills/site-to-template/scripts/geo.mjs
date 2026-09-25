// Settled geometry: scroll each landmark to the viewport centre, wait for reveal/parallax to settle, measure.
// node geo.mjs <url> <out.json> <width> <height> <config.json> [side=ref|clone] [settleMs=900]
import fs from 'node:fs';
import { launch, openPage, loadJSON } from './_lib.mjs';
const [url, out, w = 1440, h = 900, cfgPath, side = 'ref', settle = 900] = process.argv.slice(2);
const cfg = loadJSON(cfgPath); const L = cfg.landmarks || []; const MAP = side === 'clone' ? cfg.map || {} : {};
const b = await launch(); const p = await openPage(b, url, w, h);
const res = { _H: await p.evaluate(() => document.documentElement.scrollHeight) };
for (const s of L) {
  const q = MAP[s] || s;
  const ok = await p.evaluate((q) => { const e = document.querySelector(q); if (!e) return false; e.scrollIntoView({ block: 'center' }); return true; }, q);
  if (!ok) { res[s] = null; continue; }
  await p.waitForTimeout(+settle);
  res[s] = await p.evaluate((q) => { const r = document.querySelector(q).getBoundingClientRect(); return [r.x, r.y + scrollY, r.width, r.height].map(Math.round); }, q);
}
fs.writeFileSync(out, JSON.stringify(res).replace(/\],/g, '],\n'));
console.log('H', res._H, 'missing:', Object.keys(res).filter((k) => res[k] === null).join(' ') || 'none');
await b.close();
