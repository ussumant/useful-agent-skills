# Components — copy-paste snippets

All classes live in `template.html`. Replace `sN-` marker ids per diagram so
ids never collide on one page.

## Shot skeleton

```html
<div id="shot3" class="shot">
  <div class="shot-head">
    <span class="shot-index">03</span>
    <div><h2>Title in Pixelify, four to six words</h2><p>One mono sentence: what the reader is looking at.</p></div>
  </div>
  <div class="scene"> …the picture… </div>
  <div class="callout"><strong>One-line takeaway.</strong><p>One mono sentence.</p></div>
  <p class="footnote">Method caveat, if any.</p>
</div>
```

## Cards

```html
<div class="card"><span class="label">Name</span><span class="sub">mono body, ≤ 14 words</span></div>
<div class="card tint-orange"><span class="tag">Seed · where it entered</span><span class="sub">“…”</span></div>
<div class="card solid"><span class="tag">Output</span><span class="sub">“the line the reader came for…”</span></div>
<div class="card gray"><span class="tag">Canned · never happened</span><span class="sub strike">“the puppet line”</span></div>
<div class="card gray"><span class="badge-x">×</span><span class="sub">missing piece</span></div>
<div class="card dashed tint-orange"><span class="tag">A voice that is not anyone on this floor</span><span class="sub">“whisper text”</span></div>
```

## Arrow markers (one `<defs>` per diagram, unique ids)

```html
<defs>
  <marker id="s3-blue"   viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="#1a52e0"/></marker>
  <marker id="s3-orange" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="#d66b2f"/></marker>
  <marker id="s3-gray"   viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="#aaa"/></marker>
</defs>
```

## Connectors (inline SVG between cards, `class="connector"`)

```html
<!-- solid blue flow, left→right -->
<svg class="connector" viewBox="0 0 50 40" width="50" height="40"><path d="M4 20 H42" stroke="#1a52e0" stroke-width="2" fill="none" marker-end="url(#s3-blue)"/></svg>
<!-- solid blue, top→bottom (stack in a .col) -->
<svg class="connector" viewBox="0 0 40 34" width="40" height="34"><path d="M20 2 V26" stroke="#1a52e0" stroke-width="2" fill="none" marker-end="url(#s3-blue)"/></svg>
<!-- dashed orange intervention / return -->
<svg class="connector" viewBox="0 0 70 40" width="70" height="40"><path d="M4 20 H60" stroke="#d66b2f" stroke-width="1.7" stroke-dasharray="5 5" fill="none" marker-end="url(#s3-orange)"/></svg>
<!-- curved orange return edge (absolute-positioned svg over the scene) -->
<svg style="position:absolute;left:640px;top:120px;overflow:visible" viewBox="0 0 220 160" width="220" height="160"><path d="M200 8 C 200 90, 120 120, 12 118" stroke="#d66b2f" stroke-width="1.7" stroke-dasharray="5 5" fill="none" marker-end="url(#s3-orange)"/></svg>
<!-- gray path that stops short with an × (the road not taken) -->
<svg class="connector" viewBox="0 0 120 40" width="120" height="40"><path d="M4 20 H84" stroke="#aaa" stroke-width="1.5" stroke-dasharray="4 4" fill="none"/><text x="92" y="25" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="14" fill="#999">×</text></svg>
```

## Network circles

```html
<!-- plain (person) -->
<svg viewBox="0 0 76 76" width="76" height="76"><circle cx="38" cy="38" r="32" fill="#f5f7ff" stroke="#1a52e0" stroke-width="1.5"/><text x="38" y="35" text-anchor="middle" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="13" font-weight="700" fill="#000">Irving</text><text x="38" y="52" text-anchor="middle" font-family="ui-monospace,Menlo,monospace" font-size="11" fill="#555">10:35</text></svg>
<!-- origin (solid) -->
<svg viewBox="0 0 76 76" width="76" height="76"><circle cx="38" cy="38" r="32" fill="#1a52e0"/><text x="38" y="35" text-anchor="middle" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="13" font-weight="700" fill="#fff">Isabella</text><text x="38" y="52" text-anchor="middle" font-family="ui-monospace,Menlo,monospace" font-size="10" fill="#d9e5ff">origin</text></svg>
<!-- hollow gray (scripted / invalid) -->
<svg viewBox="0 0 60 60" width="60" height="60"><circle cx="30" cy="30" r="24" fill="#fff" stroke="#aaa" stroke-width="1.5" stroke-dasharray="4 3"/><text x="30" y="35" text-anchor="middle" font-family="ui-monospace,Menlo,monospace" font-size="12" fill="#999">B</text></svg>
<!-- orange (the intervener) -->
<svg viewBox="0 0 76 76" width="76" height="76"><circle cx="38" cy="38" r="32" fill="#fff3ea" stroke="#d66b2f" stroke-width="1.5"/><text x="38" y="42" text-anchor="middle" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="13" font-weight="700" fill="#8a4a25">Milchick</text></svg>
```

## Timeline baseline that thickens (growth over days)

```html
<svg viewBox="0 0 960 40" width="960" height="40" preserveAspectRatio="none">
  <circle cx="90" cy="20" r="5" fill="#1a52e0"/><path d="M97 20 H278" stroke="#1a52e0" stroke-width="1.5"/>
  <circle cx="285" cy="20" r="5" fill="#1a52e0"/><path d="M294 20 H471" stroke="#1a52e0" stroke-width="3"/>
  <circle cx="480" cy="20" r="5.2" fill="#1a52e0"/><path d="M491 20 H664" stroke="#1a52e0" stroke-width="4.5"/>
  <circle cx="675" cy="20" r="5.6" fill="#1a52e0"/><path d="M687 20 H858" stroke="#1a52e0" stroke-width="6"/>
  <circle cx="870" cy="20" r="7" fill="#1a52e0"/>
</svg>
<!-- under it: a 5-column grid; each column = <div class="mono-caption">MON</div><small>day 1 · #195</small> + a .card with the ≤14-word quote -->
```

## Timed track (two-track / rewind scenes)

```html
<svg viewBox="0 0 960 30" width="960" height="30"><path d="M40 15 H900" stroke="#1a52e0" stroke-width="2"/><circle cx="40" cy="15" r="7" fill="#1a52e0"/><circle cx="330" cy="15" r="7" fill="#1a52e0"/><circle cx="620" cy="15" r="7" fill="#1a52e0"/><circle cx="900" cy="15" r="7" fill="#bbb"/></svg>
<!-- under it, a grid of time labels: <b class="mono-caption">08:46</b><br><span class="sub">Milchick announces it himself</span>; the gray node gets a gray label, e.g. "Burt & Irving never spoke" -->
```

## Ranked bars with stacked scores (retrieval / ranking traces)

```html
<div class="row" style="border-bottom:1px solid #e3e3e3;padding:10px 0;">
  <div style="width:290px;"><b style="font-family:var(--sans);color:#000;font-size:14px;">#2542</b><br><span class="sub">day 4</span><br><span class="sub" style="font-style:italic;color:#777;">“I can feel the days running short”</span></div>
  <div class="grow" style="display:flex;height:22px;"><div style="width:45%;background:#a8c0f7;"></div><div style="width:37%;background:#1a52e0;"></div><div style="width:8%;background:#d66b2f;"></div></div>
  <div style="width:110px;text-align:right;" class="sub">reflection</div>
</div>
<!-- legend: <div class="legend"><div><i style="background:#a8c0f7"></i>recency</div><div><i style="background:#1a52e0"></i>importance</div><div><i style="background:#d66b2f"></i>relevance</div></div> -->
```

## Fail → rule ladder

```html
<div class="row top">
  <div class="col" style="width:400px;"><div class="card tint-orange"><span class="sub">What broke, ≤ 12 words.</span></div></div>
  <svg class="connector" viewBox="0 0 50 40" width="50" height="40"><path d="M4 20 H42" stroke="#1a52e0" stroke-width="2" fill="none" marker-end="url(#s6-blue)"/></svg>
  <div class="col grow" style="background:var(--panel);padding:14px;"><span class="mono-caption">House law</span><div class="card"><span class="sub">What it became, ≤ 10 words.</span></div></div>
</div>
```

## Verdict words and side boxes

```html
<div class="verdict">theology</div>
<div class="card dashed gray" style="text-align:center;"><span class="tag" style="color:#8a8a8a;">Optics &amp; Design</span><span class="sub">never entered</span></div>
```
