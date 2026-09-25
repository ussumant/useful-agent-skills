// Inventory every element that has event listeners (via CDP), plus window/document listeners.
// node interactions.mjs <url> [width=1440] [height=900]   → prints "element  events" lines to stdout
import { launch, openPage, revealAll } from './_lib.mjs';
const [url, w = 1440, h = 900] = process.argv.slice(2);
const b = await launch(); const p = await openPage(b, url, w, h); await revealAll(p);
const cdp = await p.context().newCDPSession(p);
await cdp.send('DOM.enable');
const { root } = await cdp.send('DOM.getDocument', { depth: -1, pierce: true });
const NOISE = new Set(['load', 'error']); const lines = [];
const walk = async (n) => {
  if (n.nodeType === 1 && !['script', 'link', 'style', 'meta'].includes(n.localName)) {
    const a = {}; for (let i = 0; i < (n.attributes || []).length; i += 2) a[n.attributes[i]] = n.attributes[i + 1];
    try {
      const { object } = await cdp.send('DOM.resolveNode', { nodeId: n.nodeId });
      const { listeners } = await cdp.send('DOMDebugger.getEventListeners', { objectId: object.objectId });
      const ev = [...new Set(listeners.map((l) => l.type))].filter((t) => !NOISE.has(t));
      if (ev.length) lines.push(`${n.localName}${a.class ? '.' + a.class.trim().split(/\s+/).slice(0, 4).join('.') : ''}${a['aria-label'] ? ` [${a['aria-label']}]` : ''}`.padEnd(72) + ev.join(','));
    } catch {}
  }
  for (const c of n.children || []) await walk(c);
};
await walk(root);
for (const [label, expr] of [['WINDOW', 'window'], ['DOCUMENT', 'document']]) {
  const { result } = await cdp.send('Runtime.evaluate', { expression: expr });
  const { listeners } = await cdp.send('DOMDebugger.getEventListeners', { objectId: result.objectId });
  lines.push(`${label}: ${[...new Set(listeners.map((l) => l.type))].join(',')}`);
}
console.log(lines.join('\n'));
console.log(`\n${lines.length - 2} interactive elements. Media elements: ${await p.evaluate(() => document.querySelectorAll('video,audio').length)} (headless Chromium cannot decode H.264 — blank media here may render fine in real Chrome).`);
await b.close();
