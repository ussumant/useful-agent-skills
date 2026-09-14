#!/usr/bin/env node
// shoot.mjs — reusable headless smoke harness (puppeteer).
//
// Usage:
//   node shoot.mjs <plan.json>
//
// Plan JSON shape:
//   {
//     "url": "file:///abs/path/to/page.html",   // or "path": "relative/or/abs/file.html"
//     "steps": [
//       { "type": "click", "selector": "#clockInBtn" },
//       { "type": "wait",  "ms": 300 },
//       { "type": "down",  "key": "ArrowRight" },      // real page.keyboard.down (window-level keydown)
//       { "type": "wait",  "ms": 400 },
//       { "type": "up",    "key": "ArrowRight" },      // real page.keyboard.up (window-level keyup)
//       { "type": "press", "key": "Enter" },           // down+up in one step
//       { "type": "waitFor", "expr": "__viz.state().connected", "timeoutMs": 20000 },
//       { "type": "shot",  "path": "scratchpad/out.png" },
//       { "type": "eval",  "expr": "window.__mark", "label": "afterWalk" }
//     ]
//   }
//
// Output: prints one JSON line per "eval" step ({label, value}) to stdout, and
// a final JSON summary line { ok, results: [...] } — a caller can grep/parse.
//
// Notes:
//   - Uses the global puppeteer already installed for md-to-pdf
//     (~/.npm-global/lib/node_modules/md-to-pdf/node_modules/puppeteer) — no local
//     node_modules dependency in this repo.
//   - "click" clicks a real DOM selector (page.click) — use this for HTML/menu
//     buttons like #clockInBtn. It does NOT focus the Phaser canvas.
//   - "down"/"up"/"press" dispatch REAL keyboard events via page.keyboard —
//     needed for games (like this one) that read a window-level `held[]` map
//     rather than requiring canvas focus.
//   - "eval" runs an arbitrary expression in page context via page.evaluate
//     and returns the JSON-serializable result.

import { createRequire } from "node:module";
import { readFileSync, mkdirSync } from "node:fs";
import { dirname, resolve as resolvePath } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const require = createRequire(import.meta.url);

// Resolve puppeteer: PUPPETEER_PATH env → local node_modules (cwd, then this file's dir) → global npm root.
function loadPuppeteer() {
  const { execSync } = require("node:child_process");
  const candidates = [];
  if (process.env.PUPPETEER_PATH) candidates.push(process.env.PUPPETEER_PATH);
  candidates.push("puppeteer");
  try { candidates.push(resolvePath(execSync("npm root -g", { encoding: "utf8" }).trim(), "puppeteer")); } catch (e) {}
  try { candidates.push(resolvePath(execSync("npm root -g", { encoding: "utf8" }).trim(), "md-to-pdf/node_modules/puppeteer")); } catch (e) {}
  for (const c of candidates) { try { return require(c); } catch (e) {} }
  console.error("FATAL: puppeteer not found. Run `npm i puppeteer` next to your diagrams, or set PUPPETEER_PATH=/path/to/node_modules/puppeteer");
  process.exit(1);
}
const puppeteer = loadPuppeteer();

const planPath = process.argv[2];
if (!planPath) {
  console.error("usage: node shoot.mjs <plan.json>");
  process.exit(1);
}

const plan = JSON.parse(readFileSync(resolvePath(planPath), "utf8"));

function resolveTargetUrl(plan) {
  if (plan.url) return plan.url;
  if (plan.path) {
    const abs = resolvePath(plan.path);
    return pathToFileURL(abs).href;
  }
  throw new Error("plan must have a 'url' or 'path' field");
}

async function runStep(page, step, results) {
  switch (step.type) {
    case "click": {
      await page.click(step.selector);
      break;
    }
    case "clickAt": {
      // real mouse click at coordinates the page computes:
      //   { "type":"clickAt", "expr":"__viz.agentScreen('mark')" }
      // Use this rather than a debug hook when the click handler itself
      // (canvas hit-testing, say) is the thing under test.
      const pt = await page.evaluate(new Function(`return (${step.expr});`));
      if (!pt || typeof pt.x !== "number") throw new Error(`clickAt got no point from: ${step.expr}`);
      await page.mouse.click(pt.x, pt.y);
      results.push({ type: "clickAt", expr: step.expr, point: pt });
      console.log(JSON.stringify({ type: "clickAt", expr: step.expr, point: pt }));
      break;
    }
    case "dragAt": {
      // real mouse drag between two page-computed points:
      //   { "type":"dragAt", "fromExpr":"...", "toExpr":"...", "steps":15 }
      // Use this to exercise an actual pointer-driven drag (canvas hit
      // testing, bound-arrow recompute) rather than a debug-hook shortcut.
      const from = await page.evaluate(new Function(`return (${step.fromExpr});`));
      const to = await page.evaluate(new Function(`return (${step.toExpr});`));
      if (!from || typeof from.x !== "number") throw new Error(`dragAt got no start point from: ${step.fromExpr}`);
      if (!to || typeof to.x !== "number") throw new Error(`dragAt got no end point from: ${step.toExpr}`);
      await page.mouse.move(from.x, from.y);
      await page.mouse.down();
      await page.mouse.move(to.x, to.y, { steps: step.steps ?? 15 });
      await page.mouse.up();
      const entry = { type: "dragAt", from, to };
      results.push(entry);
      console.log(JSON.stringify(entry));
      break;
    }
    case "focus": {
      await page.focus(step.selector);
      break;
    }
    case "down": {
      await page.keyboard.down(step.key);
      break;
    }
    case "up": {
      await page.keyboard.up(step.key);
      break;
    }
    case "press": {
      await page.keyboard.press(step.key, step.options || {});
      break;
    }
    case "wait": {
      await new Promise(r => setTimeout(r, step.ms ?? 500));
      break;
    }
    case "waitFor": {
      // Gate a capture on world state instead of on luck:
      //   { "type":"waitFor", "expr":"__viz.state().clock >= '12:00'", "timeoutMs":60000 }
      await page.waitForFunction(
        new Function(`return !!(${step.expr});`),
        { timeout: step.timeoutMs ?? 30000, polling: step.polling ?? 100 }
      );
      results.push({ type: "waitFor", expr: step.expr });
      console.log(JSON.stringify({ type: "waitFor", expr: step.expr }));
      break;
    }
    case "shot": {
      const outPath = resolvePath(step.path);
      mkdirSync(dirname(outPath), { recursive: true });
      if (step.selector) {
        // element-clipped capture (crisp canvas grab for design backdrops)
        const el = await page.$(step.selector);
        if (!el) throw new Error(`shot selector not found: ${step.selector}`);
        await el.screenshot({ path: outPath });
      } else if (step.clip) {
        // region crop, for reading fine detail (FX, glyphs) off a canvas
        await page.screenshot({ path: outPath, clip: step.clip });
      } else {
        await page.screenshot({ path: outPath, fullPage: !!step.fullPage });
      }
      results.push({ type: "shot", path: outPath });
      console.log(JSON.stringify({ type: "shot", path: outPath }));
      break;
    }
    case "eval": {
      const value = await page.evaluate(new Function(`return (${step.expr});`));
      const entry = { type: "eval", label: step.label || step.expr, value };
      results.push(entry);
      console.log(JSON.stringify(entry));
      break;
    }
    default:
      throw new Error(`unknown step type: ${step.type}`);
  }
}

async function main() {
  const targetUrl = resolveTargetUrl(plan);
  const launchOpts = {
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  };
  // Optional persistent profile — for verifying localStorage/IndexedDB
  // survives a full browser close/reopen (default: fresh profile per run,
  // same as before this option existed).
  if (plan.userDataDir) launchOpts.userDataDir = resolvePath(plan.userDataDir);
  const browser = await puppeteer.launch(launchOpts);
  const results = [];
  try {
    const page = await browser.newPage();
    const vp = plan.viewport || {};
    await page.setViewport({
      width: vp.width ?? 1280,
      height: vp.height ?? 800,
      deviceScaleFactor: vp.deviceScaleFactor ?? 1,
    });
    page.on("console", msg => console.error(`[page console] ${msg.text()}`));
    page.on("pageerror", err => console.error(`[page error] ${err}`));

    // Optional failure injection — for proving hardened pages fail loudly
    // instead of going silently white. Each rule: { contains, action }
    // where action is "abort" (rejects immediately) or "hang" (never
    // responds — the request just sits there, like a stalled CDN).
    // Default (no plan.network): everything passes through untouched.
    if (Array.isArray(plan.network) && plan.network.length) {
      await page.setRequestInterception(true);
      page.on("request", (req) => {
        const rule = plan.network.find(r => req.url().includes(r.contains));
        if (!rule) { req.continue(); return; }
        if (rule.action === "abort") { req.abort("failed"); return; }
        if (rule.action === "hang") { /* never call continue/abort/respond */ return; }
        req.continue();
      });
    }

    // A hung ("action":"hang") request can block the HTML parser forever, so
    // none of puppeteer's waitUntil conditions (load/domcontentloaded/
    // networkidle*) ever resolve — there's no "commit"-only option in this
    // puppeteer-core version. Such plans pass a short gotoTimeoutMs; a
    // navigation-timeout here just means "still loading, as expected" — the
    // frame keeps loading in the background, and the "waitFor" step below
    // polls actual page state instead. Any other goto error still throws.
    try {
      await page.goto(targetUrl, {
        waitUntil: plan.waitUntil || "load",
        timeout: plan.gotoTimeoutMs ?? 30000,
      });
    } catch (e) {
      if (!/timeout/i.test(String(e && e.message))) throw e;
      console.error(`[shoot] goto timed out after ${plan.gotoTimeoutMs ?? 30000}ms (expected for a hang-injection plan) — continuing`);
    }

    for (const step of plan.steps || []) {
      await runStep(page, step, results);
    }

    console.log(JSON.stringify({ ok: true, results }));
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack ? e.stack : e), results }));
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
}

main();
