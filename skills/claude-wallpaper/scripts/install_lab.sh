#!/bin/zsh
# install_lab.sh <mods folder> <lab dir>
# Copies the wallpaper-lab mod into a session's mods folder and points it at <lab dir>.
# <mods folder> is the path the plugin-authoring skill prints under WHERE TO WRITE IT. It is named after the session
# id, so it changes after a resume or a /model switch: load that skill again and use the path it prints now.
set -e
if [ $# -ne 2 ]; then echo "usage: install_lab.sh <mods folder> <lab dir>"; exit 2; fi
HERE=${0:A:h}
mkdir -p "$1/wallpaper-lab" "$2"
MODS=${1:A}; LAB=${2:A}
cp -R "$HERE/../reference/lab-mod/." "$MODS/wallpaper-lab/"
sed -i '' "s|__LAB_DIR__|$LAB|" "$MODS/wallpaper-lab/hooks/register.tsx"
: > "$LAB/tick"
rm -f "$LAB/drawn.json"
claude plugin validate "$MODS/wallpaper-lab" 2>&1 | grep -E "Validation (passed|failed)|Found [0-9]+ error" || true
echo "wallpaper-lab is in $MODS/wallpaper-lab, reading $LAB. It loads when this turn ends."
