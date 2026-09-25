// Shared helpers: config loading, browser launch, "reveal everything once" scroll.
import fs from 'node:fs';
import { chromium } from 'playwright';
export const loadJSON = (p, d = {}) => (p && fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, 'utf8')) : d);
export const launch = () => chromium.launch();
export async function openPage(browser, url, w, h) {
  const page = await browser.newPage({ viewport: { width: +w, height: +h } });
  await page.goto(url, { waitUntil: 'networkidle' });
  return page;
}
// Scroll the whole page once so scroll-reveal / lazy content has fired, then return to top.
export async function revealAll(page, step = 450, pause = 90) {
  await page.evaluate(async ([step, pause]) => {
    for (let y = 0; y < document.documentElement.scrollHeight; y += step) { scrollTo(0, y); await new Promise((r) => setTimeout(r, pause)); }
    scrollTo(0, 0);
  }, [step, pause]);
}
