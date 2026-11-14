#!/bin/zsh
# show.sh <lab dir> <scene.svg> <word> [look json]: put a wallpaper in the lab and wait until the theme reports drawing it
# show.sh <lab dir> --off: stop the lab (empties the tick file)
D="$1"
if [ "$2" = "--off" ]; then : > "$D/tick"; exit 0; fi
[ -n "$3" ] || { echo "usage: show.sh <lab dir> <scene.svg> <word> [look json] | show.sh <lab dir> --off" >&2; exit 2; }
cp "$2" "$D/scene.svg"
if [ -n "$4" ]; then print -r -- "$4" > "$D/look.json"; else rm -f "$D/look.json"; fi
print -r -- "$3" > "$D/tick"
for i in {1..24}; do
  if grep -q "wallpaper-lab-$3\"" "$D/drawn.json" 2>/dev/null; then sleep 1.2; echo "drawn: $(cat "$D/drawn.json")"; exit 0; fi
  sleep 0.5
done
echo "NOT drawn after 12 s: $(cat "$D/drawn.json" 2>/dev/null)"; exit 1
