#!/bin/bash
# Self-test: films the example todo app (add three todos, reload, they're still there) and cuts the clip.
#   bash run-example.sh [OUT_DIR]     (default ./release-clip-example). Needs node + puppeteer, python3, ffmpeg.
set -e
SKILL="$(cd "$(dirname "$0")/.." && pwd)"; OUT="$(mkdir -p "${1:-release-clip-example}" && cd "${1:-release-clip-example}" && pwd)"
APP="file://$SKILL/examples/todo-app/index.html"
S="node $SKILL/step.js"
mkdir -p "$OUT/takes"; cp "$SKILL/examples/plan.json" "$OUT/plan.json"
node "$SKILL/browser.js" 1280x800 2 > "$OUT/browser.log" 2>&1 & BROWSER=$!
trap 'kill $BROWSER 2>/dev/null || true' EXIT
until grep -q ready "$OUT/browser.log" 2>/dev/null; do sleep 0.2; done
take() {   # take NAME — start filming; `stop_take NAME` stops it and encodes
  node "$SKILL/record.js" "$OUT/takes/$1" > "$OUT/takes/$1.log" 2>&1 &
  until grep -q recording "$OUT/takes/$1.log" 2>/dev/null; do sleep 0.1; done
}
stop_take() { touch "$OUT/takes/$1/STOP"; until grep -q stopped "$OUT/takes/$1.log" 2>/dev/null; do sleep 0.1; done
        python3 "$SKILL/encode.py" "$OUT/takes/$1" "$OUT/takes/$1.mp4"; }

$S goto "$APP" '#text'; $S eval "localStorage.clear()"; $S goto "$APP" '#text'; $S move 900 640
take add
sleep 0.8
$S glideto '#text' 700; $S clickhere; $S type 'Buy milk'; $S key Enter; sleep 0.4
$S type 'Call the bank'; $S key Enter; sleep 0.4
$S type 'Book flights'; $S key Enter; sleep 0.9
$S glideto 'li:nth-child(2) input' 700; $S clickhere; sleep 1.8
stop_take add

take reload
$S goto "$APP" '#text'; $S move 900 640; sleep 2.6
stop_take reload

python3 "$SKILL/compose.py" "$OUT/plan.json"
