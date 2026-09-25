// Interaction test template: copy next to your clone, edit the checks, run with the clone served locally.
// node itest.template.mjs <url>
import { chromium } from 'playwright';
const url = process.argv[2] || 'http://localhost:8787/';
const b = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });
const p = await b.newPage({ viewport: { width: 1440, height: 900 } });
const errors = []; p.on('pageerror', (e) => errors.push(e.message)); p.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
await p.goto(url, { waitUntil: 'networkidle' }); await p.waitForTimeout(800);
let fails = 0; const check = (name, ok) => { console.log((ok ? 'PASS ' : 'FAIL ') + name); fails += !ok; };

// --- examples: replace selectors with your own ---
// drag: press, move, release, then assert the element moved
// const box = await (await p.$('.sticker')).boundingBox();
// await p.mouse.move(box.x + 10, box.y + 10); await p.mouse.down(); await p.mouse.move(box.x + 120, box.y + 60, { steps: 8 }); await p.mouse.up();
// check('sticker drags', await p.evaluate(() => document.querySelector('.sticker').style.translate !== ''));
// modal: open, assert visible, Esc closes
// await p.click('[data-open]'); await p.waitForTimeout(400); check('modal opens', await p.evaluate(() => !document.querySelector('#modal').hidden));
// await p.keyboard.press('Escape'); await p.waitForTimeout(300); check('Esc closes', await p.evaluate(() => document.querySelector('#modal').hidden));
// accordion, toggle, hover pill: click/hover, then assert class or computed opacity

// Guard against the classic bug: an invisible overlay intercepting clicks.
check('nothing invisible covers the page centre', await p.evaluate(() => {
  const e = document.elementFromPoint(innerWidth / 2, innerHeight / 2); const cs = getComputedStyle(e);
  return !(cs.opacity === '0' || e.hidden);
}));
check('no console errors', errors.length === 0); if (errors.length) console.log(errors.join('\n'));
await b.close(); process.exit(fails ? 1 : 0);
