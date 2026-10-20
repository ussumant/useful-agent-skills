// Shared by browser.js, step.js, record.js and cards.js: find puppeteer and a Chrome to drive.
const { execSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

// PUPPETEER_PATH → local node_modules → global npm root (plain, then md-to-pdf's copy).
function loadPuppeteer() {
  const tries = [];
  if (process.env.PUPPETEER_PATH) tries.push(process.env.PUPPETEER_PATH);
  tries.push('puppeteer', path.join(__dirname, 'node_modules', 'puppeteer'));
  try {
    const g = execSync('npm root -g', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    tries.push(path.join(g, 'puppeteer'), path.join(g, 'md-to-pdf', 'node_modules', 'puppeteer'));
  } catch (e) {}
  for (const t of tries) { try { return require(t); } catch (e) {} }
  console.error('FATAL: puppeteer not found. Run `npm i puppeteer` in this folder, or set PUPPETEER_PATH=/path/to/node_modules/puppeteer');
  process.exit(1);
}

// CHROME → puppeteer's own browser → an installed Chrome/Chromium.
function chromePath(puppeteer) {
  if (process.env.CHROME) return process.env.CHROME;
  try { const p = puppeteer.executablePath(); if (p && fs.existsSync(p)) return p; } catch (e) {}
  for (const c of ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '/usr/bin/google-chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser'])
    if (fs.existsSync(c)) return c;
  return undefined;
}

const PORT = Number(process.env.CLIP_PORT || 9333);
module.exports = { loadPuppeteer, chromePath, PORT };
