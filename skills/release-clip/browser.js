#!/usr/bin/env node
// node browser.js [WIDTHxHEIGHT] [DPR] — keeps one headless Chrome open on CLIP_PORT (default 9333)
// so step.js drives it and record.js films it, across many separate calls. Run it in the background.
// Every page load gets a drawn pointer and a click ring (headless Chrome draws no cursor).
// CLIP_HIDE="sel1, sel2" hides overlays that would flash in the take (VS Code: .terminal-resize-overlay).
// CLIP_PROFILE=/dir keeps the browser profile (VS Code web keeps its settings in the browser).
const fs = require('node:fs'), os = require('node:os'), path = require('node:path');
const { loadPuppeteer, chromePath, PORT } = require('./lib');
const puppeteer = loadPuppeteer();
const [W, H] = (process.argv[2] || '1280x800').split('x').map(Number);
const DPR = Number(process.argv[3] || 2);
const HIDE = process.env.CLIP_HIDE || '';
(async () => {
  const browser = await puppeteer.launch({
    headless: true, executablePath: chromePath(puppeteer),
    userDataDir: process.env.CLIP_PROFILE || fs.mkdtempSync(path.join(os.tmpdir(), 'release-clip-')),
    defaultViewport: { width: W, height: H, deviceScaleFactor: DPR },
    args: [`--remote-debugging-port=${PORT}`, '--no-first-run', '--hide-scrollbars'],
  });
  const [page] = await browser.pages();
  await page.evaluateOnNewDocument((hide) => {
    const add = () => {
      if (document.getElementById('__clip')) return;
      const st = document.createElement('style'); st.id = '__clip';
      st.textContent = (hide ? `${hide}{display:none!important}` : '') + `
        #__ptr{position:fixed;left:0;top:0;z-index:2147483647;pointer-events:none;display:none;width:22px;height:22px;transform:translate(-3px,-2px)}
        #__ring{position:fixed;z-index:2147483646;pointer-events:none;width:34px;height:34px;margin:-17px 0 0 -17px;border-radius:50%;border:3px solid #4ea1ff;opacity:0;transition:opacity .45s ease, transform .45s ease}`;
      document.documentElement.appendChild(st);
      const p = document.createElement('div'); p.id = '__ptr';
      p.innerHTML = '<svg width="22" height="22" viewBox="0 0 22 22"><path d="M3 2 L3 18 L7.5 14 L10.5 20.5 L13.5 19 L10.5 12.8 L16.5 12.8 Z" fill="#fff" stroke="#000" stroke-width="1.3" stroke-linejoin="round"/></svg>';
      const r = document.createElement('div'); r.id = '__ring';
      document.documentElement.append(p, r);
      addEventListener('mousemove', e => { p.style.display = 'block'; p.style.left = e.clientX + 'px'; p.style.top = e.clientY + 'px'; }, true);
      addEventListener('mousedown', e => { r.style.transition = 'none'; r.style.left = e.clientX + 'px'; r.style.top = e.clientY + 'px'; r.style.opacity = '1'; r.style.transform = 'scale(.5)'; r.offsetWidth; r.style.transition = ''; r.style.opacity = '0'; r.style.transform = 'scale(1.4)'; }, true);
    };
    if (document.documentElement) add();
    document.addEventListener('DOMContentLoaded', add);
  }, HIDE);
  console.log('ready', `port ${PORT}`, `${W}x${H}@${DPR}x`);
  await new Promise(() => {});
})().catch(e => { console.error('ERR', e.message); process.exit(1); });
