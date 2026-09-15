#!/bin/bash
# keep-awake — machine-stays-up machinery for unattended/overnight agent runs.
# Design: caffeinate holds idle+system sleep; a detached GUARD process re-arms
# it if it dies, and status/verify prove the sleep assertion is actually HELD
# (via pmset) instead of assuming it. Rules encoded:
#   1. caffeinate holds idle+system sleep; a GUARD re-arms it if it dies.
#   2. The guard is a DETACHED process (nohup + own pgroup, PID file) — a
#      terminal/session interrupt cannot kill it. That's the whole point:
#      an agent session that gets interrupted, killed, or restarted must not
#      take the sleep guard down with it.
#   3. status/verify prove the assertion is actually HELD (pmset), never assume.
#   4. Honesty: lid-close on battery sleeps the Mac regardless. Say so.
#
# State lives under $KEEPAWAKE_DIR (default: ~/.claude/keepawake) so it works
# whether this script is invoked from a Claude Code skill, a cron job, or a
# plain shell.
set -u
DIR="${KEEPAWAKE_DIR:-$HOME/.claude/keepawake}"; mkdir -p "$DIR"
PIDF="$DIR/guard.pid"; LOGF="$DIR/guard.log"; ENDF="$DIR/end_epoch"

now() { date +%s; }
guard_alive() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; }

case "${1:-status}" in
  on)
    HOURS="${2:-8}"
    END=$(( $(now) + HOURS*3600 )); echo "$END" > "$ENDF"
    if guard_alive; then echo "guard already running (pid $(cat "$PIDF")) — window extended to +${HOURS}h"; exit 0; fi
    # detached guard: survives session interrupts; re-arms caffeinate every 120s
    nohup bash -c '
      DIR="'"$DIR"'"
      while :; do
        END=$(cat "$DIR/end_epoch" 2>/dev/null || echo 0)
        NOW=$(date +%s)
        [ "$NOW" -ge "$END" ] && break
        if ! pgrep -q caffeinate; then
          nohup caffeinate -is -t $((END - NOW + 120)) >/dev/null 2>&1 &
          echo "$(date "+%F %T") re-armed caffeinate" >> "$DIR/guard.log"
        fi
        sleep 120
      done
      pkill -f "caffeinate -is" 2>/dev/null
      echo "$(date "+%F %T") window ended, guard exiting" >> "$DIR/guard.log"
      rm -f "$DIR/guard.pid"
    ' >/dev/null 2>&1 &
    echo $! > "$PIDF"
    # arm caffeinate immediately (don't wait for the first guard tick)
    pgrep -q caffeinate || nohup caffeinate -is -t $((HOURS*3600 + 120)) >/dev/null 2>&1 &
    sleep 1
    "$0" verify
    ;;
  off)
    [ -f "$PIDF" ] && kill "$(cat "$PIDF")" 2>/dev/null; rm -f "$PIDF" "$ENDF"
    pkill -f "caffeinate -is" 2>/dev/null
    echo "keep-awake OFF (guard + caffeinate stopped)"
    ;;
  status|verify)
    if guard_alive; then
      LEFT=$(( ($(cat "$ENDF" 2>/dev/null || now) - $(now)) / 60 ))
      echo "guard: RUNNING (pid $(cat "$PIDF"), ~${LEFT}m left) — detached, survives session interrupts"
    else
      echo "guard: not running"
    fi
    if pmset -g assertions 2>/dev/null | grep -q "PreventUserIdleSystemSleep *1"; then
      echo "sleep assertion: HELD ($(pgrep -x caffeinate | wc -l | tr -d ' ') caffeinate process(es))"
    else
      echo "sleep assertion: NOT HELD — machine can idle-sleep"
    fi
    pmset -g batt 2>/dev/null | head -1
    echo "CAVEAT: lid-close on battery sleeps the Mac regardless — leave the lid open (dark display is fine), plug in if possible."
    ;;
  *) echo "usage: keepawake.sh on [hours] | off | status"; exit 1 ;;
esac
