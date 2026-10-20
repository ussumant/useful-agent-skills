#!/usr/bin/env node
// node step.js <action> [args] — one action against the page browser.js keeps open. Each call is a new connection.
//   goto URL [SELECTOR]        load URL, wait for SELECTOR if given
//   key K [K2 ...]             press keys; combos like Meta+s, Control+Shift+p
//   type TEXT                  type like a person (15 ms per key)
//   paste FILE                 insert a file's text in one go (editors that auto-close brackets mangle typed JSON)
//   click SELECTOR             DOM click, no pointer motion
//   clickxy X Y                instant click at CSS px
//   glide X Y [MS]             eased drawn-pointer move from where it is now (default 700 ms)
//   glideto SELECTOR [TEXT] [MS]  glide to the centre of the first SELECTOR whose text matches TEXT
//   clickhere                  click where the drawn pointer is (a new connection's mouse starts at 0,0)
//   move X Y                   put the pointer there at once (shows it after a reload)
//   drag X1 Y1 X2 Y2           drag, e.g. a splitter
//   waitfor JS [MS]            wait until a page expression is true (default 30 s)
//   eval JS                    print a page expression as JSON
//   center SELECTOR [TEXT]     print "x y" of an element's centre
//   shot FILE                  screenshot (check frames between takes; never while record.js runs)
//   wait MS
const { loadPuppeteer, PORT } = require('./lib');
const puppeteer = loadPuppeteer();
const sleep = ms => new Promise(r => setTimeout(r, ms));
const ease = t => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
(async () => {
  const browser = await puppeteer.connect({ browserURL: `http://127.0.0.1:${PORT}`, defaultViewport: null });
  const [page] = await browser.pages();
  const [action, ...args] = process.argv.slice(2);
  const ptr = () => page.evaluate(() => { const p = document.getElementById('__ptr'); return p && p.style.left ? [parseFloat(p.style.left), parseFloat(p.style.top)] : null; });
  const centre = (sel, text) => page.evaluate((sel, text) => {
    const el = [...document.querySelectorAll(sel)].find(e => !text || e.innerText.trim() === text || new RegExp(text).test(e.innerText));
    if (!el) return null; const r = el.getBoundingClientRect(); return [Math.round(r.x + r.width / 2), Math.round(r.y + r.height / 2)];
  }, sel, text || '');
  const glide = async (x, y, ms) => {
    const from = (await ptr()) || [x - 200, y - 120];
    const t0 = Date.now();
    for (;;) { const t = Math.min(1, (Date.now() - t0) / ms), e = ease(t); await page.mouse.move(from[0] + (x - from[0]) * e, from[1] + (y - from[1]) * e); if (t >= 1) break; await sleep(16); }
  };
  if (action === 'goto') { await page.goto(args[0], { waitUntil: 'domcontentloaded' }); if (args[1]) await page.waitForSelector(args[1], { timeout: 60000 }); }
  else if (action === 'key') { for (const k of args) { const parts = k.split('+'); for (const p of parts.slice(0, -1)) await page.keyboard.down(p); await page.keyboard.press(parts[parts.length - 1]); for (const p of parts.slice(0, -1).reverse()) await page.keyboard.up(p); await sleep(150); } }
  else if (action === 'type') { await page.keyboard.type(args.join(' '), { delay: 15 }); }
  else if (action === 'paste') { await page.keyboard.sendCharacter(require('fs').readFileSync(args[0], 'utf8')); }
  else if (action === 'click') { await page.click(args[0]); }
  else if (action === 'clickxy') { await page.mouse.click(Number(args[0]), Number(args[1])); }
  else if (action === 'glide') { await glide(Number(args[0]), Number(args[1]), Number(args[2] || 700)); }
  else if (action === 'glideto') {
    const ms = Number(args.find((a, i) => i > 0 && /^\d+$/.test(a)) || 700);
    const text = args[1] && !/^\d+$/.test(args[1]) ? args[1] : '';
    const c = await centre(args[0], text); if (!c) throw new Error(`no element ${args[0]} ${text}`);
    await glide(c[0], c[1], ms);
  }
  else if (action === 'clickhere') { const p = await ptr(); if (!p) throw new Error('no drawn pointer yet: move or glide first'); await page.mouse.move(p[0], p[1]); await page.mouse.down(); await sleep(90); await page.mouse.up(); }
  else if (action === 'move') { await page.mouse.move(Number(args[0]), Number(args[1])); }
  else if (action === 'drag') { const [x1, y1, x2, y2] = args.map(Number); await page.mouse.move(x1, y1); await page.mouse.down(); await page.mouse.move(x2, y2, { steps: 12 }); await page.mouse.up(); }
  else if (action === 'waitfor') { await page.waitForFunction(args[0], { timeout: Number(args[1] || 30000), polling: 100 }); }
  else if (action === 'eval') { const v = await page.evaluate(args.join(' ')); if (v !== undefined) console.log(JSON.stringify(v)); }
  else if (action === 'center') { const c = await centre(args[0], args[1]); if (!c) throw new Error(`no element ${args[0]}`); console.log(c.join(' ')); }
  else if (action === 'shot') { await page.screenshot({ path: args[0] }); }
  else if (action === 'wait') { await sleep(Number(args[0])); }
  else throw new Error(`unknown action ${action}`);
  browser.disconnect();
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
