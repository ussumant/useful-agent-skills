// Rebuild examples/before.png and examples/after.png from the three example pages + the diff numbers.
// node make-pair.mjs <refShot.png> <beforeShot.png> <afterShot.png> '<before caption>' '<after caption>'   (run from examples/)
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from '../scripts/node_modules/playwright/index.mjs';
const [ref, before, after, capB, capA] = process.argv.slice(2);
const uri = (p) => 'data:image/png;base64,' + fs.readFileSync(p).toString('base64');
const page = (title, cap, left, right, rightLabel) => `<!doctype html><html><head><link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
<style>body{margin:0;background:#fff;font-family:Inter,sans-serif}#s{width:1500px;padding:36px 40px 40px;box-sizing:border-box}
h1{margin:0;font-size:30px;letter-spacing:-.02em}p.c{margin:8px 0 22px;font-size:17px;color:#555}
.row{display:flex;gap:24px}.col{flex:1}.l{font:600 13px/1 ui-monospace,monospace;letter-spacing:.06em;text-transform:uppercase;color:#888;margin-bottom:10px}
img{width:100%;display:block;border:1px solid #ddd;border-radius:8px}</style></head><body><div id="s"><h1>${title}</h1><p class="c">${cap}</p>
<div class="row"><div class="col"><div class="l">source page</div><img src="${uri(left)}"></div><div class="col"><div class="l">${rightLabel}</div><img src="${uri(right)}"></div></div></div></body></html>`;
const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1500, height: 900 }, deviceScaleFactor: 1 });
for (const [name, html] of [['before', page('Without the skill: a one-shot rebuild from a glance', capB, ref, before, 'naive rebuild')],
                            ['after', page('With site-to-template: measured rebuild, placeholder content', capA, ref, after, 'measured rebuild')]]) {
  await p.setContent(html, { waitUntil: 'networkidle' }); await p.evaluate(() => document.fonts.ready);
  await (await p.$('#s')).screenshot({ path: path.resolve(`${name}.png`) });
}
await b.close(); console.log('wrote before.png after.png');
