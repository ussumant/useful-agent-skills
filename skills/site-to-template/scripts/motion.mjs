// Sample how elements change over time (typing bubbles, frozen/animated bars) or with scroll (marquees, parallax).
// node motion.mjs <url> <config.json>
// config: { "width":1440, "height":900, "scrollTo": ".feature-row", "samples": 20, "intervalMs": 300,
//           "watch": [".bubble", ".marquee-track"], "props": ["transform","opacity"], "scrollSweep": [2900, 3300, 3700] }
import { launch, openPage, loadJSON } from './_lib.mjs';
const [url, cfgPath] = process.argv.slice(2); const c = loadJSON(cfgPath);
const b = await launch(); const p = await openPage(b, url, c.width || 1440, c.height || 900);
const read = () => p.evaluate(([W, P]) => W.map((s) => [...document.querySelectorAll(s)].slice(0, 3).map((e) => {
  const r = e.getBoundingClientRect(), cs = getComputedStyle(e);
  return `${s} ${Math.round(r.width)}x${Math.round(r.height)} "${(e.innerText || '').length}ch" ` + P.map((k) => `${k}=${cs.getPropertyValue(k)}`).join(' ');
}).join(' | ')).join('  ||  '), [c.watch, c.props || ['transform', 'opacity']]);
if (c.scrollTo) { await p.evaluate((s) => document.querySelector(s)?.scrollIntoView({ block: 'center' }), c.scrollTo); }
for (let i = 0; i < (c.samples || 20); i++) { await p.waitForTimeout(c.intervalMs || 300); console.log(`t=${((i + 1) * (c.intervalMs || 300) / 1000).toFixed(1)}s  ${await read()}`); }
for (const y of c.scrollSweep || []) { await p.evaluate((y) => scrollTo(0, y), y); await p.waitForTimeout(700); console.log(`scrollY=${y}  ${await read()}`); }
await b.close();
