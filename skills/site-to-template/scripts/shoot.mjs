// Full-page capture after a reveal pass.  node shoot.mjs <url> <out.png> [width=1440] [height=900]
import { launch, openPage, revealAll } from './_lib.mjs';
const [url, out, w = 1440, h = 900] = process.argv.slice(2);
if (!url || !out) { console.error('usage: node shoot.mjs <url> <out.png> [width] [height]'); process.exit(2); }
const b = await launch(); const p = await openPage(b, url, w, h);
await revealAll(p); await p.waitForTimeout(1200);
await p.screenshot({ path: out, fullPage: true });
console.log('page height', await p.evaluate(() => document.documentElement.scrollHeight));
await b.close();
