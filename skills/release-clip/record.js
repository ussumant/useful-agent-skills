#!/usr/bin/env node
// node record.js TAKE_DIR — films the page browser.js keeps open, until SIGTERM/SIGINT or `touch TAKE_DIR/STOP`.
// Uses the CDP screencast and saves every frame with its real timestamp (frames.json), so encode.py plays it
// at true speed. Frames only arrive when the page changes; still stretches keep their real length.
const fs = require('node:fs'), path = require('node:path');
const { loadPuppeteer, PORT } = require('./lib');
const puppeteer = loadPuppeteer();
const out = path.resolve(process.argv[2] || 'take');
fs.rmSync(out, { recursive: true, force: true }); fs.mkdirSync(out, { recursive: true });
(async () => {
  const browser = await puppeteer.connect({ browserURL: `http://127.0.0.1:${PORT}`, defaultViewport: null });
  const [page] = await browser.pages();
  const cdp = await page.createCDPSession();
  const frames = []; let offset = null, n = 0;
  cdp.on('Page.screencastFrame', f => {
    cdp.send('Page.screencastFrameAck', { sessionId: f.sessionId }).catch(() => {});   // no ack, no next frame
    const wall = Date.now() / 1000;
    if (offset === null) offset = wall - f.metadata.timestamp;
    const file = String(n++).padStart(5, '0') + '.jpg';
    fs.writeFileSync(path.join(out, file), Buffer.from(f.data, 'base64'));
    frames.push({ file, t: f.metadata.timestamp + offset });
  });
  const start = Date.now() / 1000;
  await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 92, maxWidth: 3840, maxHeight: 2400, everyNthFrame: 1 });
  console.log('recording', out);
  let stopping = false;
  const stop = async () => {
    if (stopping) return; stopping = true;
    const end = Date.now() / 1000;
    await cdp.send('Page.stopScreencast').catch(() => {});
    fs.writeFileSync(path.join(out, 'frames.json'), JSON.stringify({ start, end, frames }));
    console.log('stopped', frames.length, 'frames', (end - start).toFixed(1) + 's');
    browser.disconnect(); process.exit(0);
  };
  process.on('SIGTERM', stop); process.on('SIGINT', stop);
  setInterval(() => { if (fs.existsSync(path.join(out, 'STOP'))) stop(); }, 100);
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
