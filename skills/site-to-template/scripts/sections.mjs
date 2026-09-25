// Matched viewport screenshots of each section on the reference and the clone, same scroll + same settle time.
// node sections.mjs <config.json>
// config: { "ref": url, "clone": url, "width": 1440, "height": 900, "out": "sec", "settleMs": 1600,
//           "sections": [["hero", 0], ["pricing", 4700], ["footer", 99999]], "slowSections": { "features": 4200 } }
import fs from 'node:fs';
import { launch, openPage, revealAll, loadJSON } from './_lib.mjs';
const c = loadJSON(process.argv[2]); const out = c.out || 'sec'; fs.mkdirSync(out, { recursive: true });
const b = await launch();
for (const [side, url] of [['ref', c.ref], ['clone', c.clone]]) {
  const p = await openPage(b, url, c.width || 1440, c.height || 900); await revealAll(p);
  for (const [name, y] of c.sections) {
    await p.evaluate((y) => scrollTo(0, y), y);
    await p.waitForTimeout((c.slowSections || {})[name] || c.settleMs || 1600);
    await p.screenshot({ path: `${out}/${name}-${side}.png` });
  }
  await p.close();
}
await b.close();
console.log(`wrote ${c.sections.length * 2} shots to ${out}/  (pair them with: python3 sbs.py ${out})`);
