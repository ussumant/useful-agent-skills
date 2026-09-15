#!/bin/bash
# codex-dispatch — a gated wrapper around the Codex CLI.
#
# Adds four things the bare `codex` binary doesn't have:
#   1. a pre-dispatch auth/liveness check (fail fast, don't burn a run on a dead seat)
#   2. a diff-size cap on review-shaped dispatches (don't hand Codex a 5000-line diff)
#   3. a one-review-per-push dedup gate (don't re-review a SHA you already reviewed)
#   4. a ledger of every dispatch, so cost/volume is auditable after the fact
#
# Model and reasoning-effort are NOT hardcoded — set them via env vars per your
# plan/subscription. Codex CLI flags and model names change across versions;
# run `codex --help` / `codex exec --help` to confirm what your install supports.
set -euo pipefail

STATE_HOME="${CODEX_DISPATCH_HOME:-$HOME/.codex-dispatch}"
LEDGER_FILE="${CODEX_DISPATCH_LEDGER:-$STATE_HOME/ledger.log}"
DEDUP_FILE="$STATE_HOME/last-reviewed-sha.tsv"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Optional passthrough — unset by default, so codex uses its own defaults
# unless you pin something. Examples: CODEX_DISPATCH_MODEL=gpt-5-high,
# CODEX_DISPATCH_EFFORT=medium. Confirm valid values with `codex --help`.
DISPATCH_MODEL="${CODEX_DISPATCH_MODEL:-}"
DISPATCH_EFFORT="${CODEX_DISPATCH_EFFORT:-}"

DIFF_CAP="${CODEX_DISPATCH_DIFF_CAP:-1500}"   # changed lines (insertions+deletions)
BASE_REF="${CODEX_DISPATCH_BASE_REF:-}"        # empty = auto-detect below

die() { echo "codex-dispatch ERROR: $*" >&2; exit 1; }
gate_die() { echo "codex-dispatch: $*" >&2; exit 3; }

mkdir -p "$STATE_HOME"

detect_base_ref() {
  local run_cwd=$1
  if [[ -n "$BASE_REF" ]]; then
    echo "$BASE_REF"
    return
  fi
  local head_ref
  head_ref=$(git -C "$run_cwd" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
  if [[ -n "$head_ref" ]]; then
    echo "$head_ref"
    return
  fi
  for candidate in main master; do
    if git -C "$run_cwd" show-ref --verify --quiet "refs/heads/$candidate"; then
      echo "$candidate"
      return
    fi
  done
  echo ""
}

diff_cap_gate() {
  local run_cwd=$1
  [[ "$(git -C "$run_cwd" rev-parse --is-inside-work-tree 2>/dev/null || true)" = "true" ]] || return 0
  local base
  base=$(detect_base_ref "$run_cwd")
  [[ -n "$base" ]] || { echo "codex-dispatch: no base ref detected, skipping diff-size cap" >&2; return 0; }
  local stat_line changed
  stat_line=$(git -C "$run_cwd" diff --shortstat "$base"...HEAD 2>/dev/null || true)
  [[ -n "$stat_line" ]] || return 0
  changed=$( { grep -oE '[0-9]+ insertion|[0-9]+ deletion' <<<"$stat_line" || true; } | \
    { grep -oE '[0-9]+' || true; } | awk '{s+=$1} END{print s+0}')
  if (( changed > DIFF_CAP )); then
    if [[ "${CODEX_DISPATCH_DIFF_OVERRIDE:-}" = "1" ]]; then
      echo "codex-dispatch: DIFF CAP OVERRIDE — $changed changed lines vs $base (cap $DIFF_CAP); proceeding" >&2
      return 0
    fi
    gate_die "diff cap — $changed changed lines vs $base exceeds CODEX_DISPATCH_DIFF_CAP=$DIFF_CAP. Split the review or set CODEX_DISPATCH_DIFF_OVERRIDE=1 (logged) to send it anyway."
  fi
  echo "codex-dispatch: diff vs $base — $changed changed lines (cap $DIFF_CAP)" >&2
}

current_sha() {
  git -C "$1" rev-parse HEAD 2>/dev/null || true
}

dedup_key() {
  local run_cwd=$1
  local origin
  origin=$(git -C "$run_cwd" remote get-url origin 2>/dev/null || echo "$run_cwd")
  local branch
  branch=$(git -C "$run_cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
  echo "${origin}#${branch}"
}

dedup_gate() {
  local run_cwd=$1
  [[ "$(git -C "$run_cwd" rev-parse --is-inside-work-tree 2>/dev/null || true)" = "true" ]] || return 0
  [[ "${CODEX_DISPATCH_NO_DEDUP:-}" != "1" ]] || return 0
  local key sha last=""
  key=$(dedup_key "$run_cwd")
  sha=$(current_sha "$run_cwd")
  [[ -n "$sha" ]] || return 0
  if [[ -f "$DEDUP_FILE" ]]; then
    last=$(awk -F'\t' -v k="$key" '$1==k{print $2}' "$DEDUP_FILE" | tail -1)
  fi
  if [[ "$last" = "$sha" ]]; then
    if [[ "${CODEX_DISPATCH_DEDUP_OVERRIDE:-}" = "1" ]]; then
      echo "codex-dispatch: DEDUP OVERRIDE — $sha already reviewed on $key; proceeding" >&2
    else
      gate_die "one-review-per-push — $sha on $key was already reviewed. Push a new commit, or set CODEX_DISPATCH_DEDUP_OVERRIDE=1 (logged) to re-review this SHA."
    fi
  fi
  DEDUP_KEY="$key"
  DEDUP_SHA="$sha"
}

record_dedup() {
  [[ -n "${DEDUP_KEY:-}" && -n "${DEDUP_SHA:-}" ]] || return 0
  printf '%s\t%s\t%s\n' "$DEDUP_KEY" "$DEDUP_SHA" "$(date '+%Y-%m-%dT%H:%M:%S%z')" >> "$DEDUP_FILE"
}

append_ledger() {
  local subcmd=$1 run_cwd=$2 status=$3
  printf '%s\t%s\t%s\tmodel=%s\teffort=%s\tstatus=%s\n' \
    "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$subcmd" "$run_cwd" \
    "${DISPATCH_MODEL:-default}" "${DISPATCH_EFFORT:-default}" "$status" >> "$LEDGER_FILE"
}

auth_gate() {
  [[ "${CODEX_DISPATCH_SKIP_AUTH:-}" != "1" ]] || return 0   # test/CI escape hatch — never set in normal use
  command -v codex >/dev/null 2>&1 || die "codex CLI not found on PATH — install it before dispatching (npm i -g @openai/codex or your equivalent)"
  # `codex login status` is a local/free check — it does not bill tokens.
  if ! codex login status >/dev/null 2>&1; then
    die "codex is not authenticated (codex login status failed) — log in before dispatching"
  fi
}

cmd="${1:-status}"

case "$cmd" in
  status)
    if command -v codex >/dev/null 2>&1; then
      echo "codex: $(codex login status 2>&1 | head -1)"
    else
      echo "codex: NOT FOUND on PATH"
    fi
    echo "ledger: $LEDGER_FILE ($( [[ -f "$LEDGER_FILE" ]] && wc -l < "$LEDGER_FILE" || echo 0 ) dispatches)"
    [[ -f "$LEDGER_FILE" ]] && tail -5 "$LEDGER_FILE"
    ;;

  ledger)
    n="${2:-20}"
    [[ -f "$LEDGER_FILE" ]] || { echo "no ledger yet at $LEDGER_FILE"; exit 0; }
    tail -n "$n" "$LEDGER_FILE"
    ;;

  detach)
    # The agent-harness Bash tool that's calling this script may hard-cap a
    # foreground call at some fixed wall-clock limit and kill the whole
    # process tree when it hits — a long `codex review`/`codex exec` run
    # foreground is how you lose the run. A session restart/resume can also
    # kill in-process children. detach.py runs the command in its own
    # session, logs to <RESULTS>.log, and writes rc=<code> to <RESULTS> on
    # exit — poll for that marker, never pgrep (codex's process name won't
    # match your command string).
    shift
    exec python3 "$SCRIPT_DIR/detach.py" "$@"
    ;;

  run)
    # Passthrough dispatch. Usage: dispatch.sh run <codex args...>
    # For `exec`, a prompt piped via stdin is the reliable form — a large
    # inline positional prompt can silently no-op on some CLI versions.
    auth_gate
    shift
    RUN_ARGS=("$@")
    RUN_ARG_COUNT=$#
    RUN_CWD="$PWD"
    for ((arg_index = 0; arg_index < RUN_ARG_COUNT; arg_index += 1)); do
      if [[ "${RUN_ARGS[arg_index]}" = "-C" ]] && (( arg_index + 1 < RUN_ARG_COUNT )); then
        RUN_CWD="${RUN_ARGS[arg_index + 1]}"
      fi
    done

    PROMPT_FILE=""
    PROMPT_PREVIEW=""
    if [[ "${RUN_ARGS[0]:-}" = "exec" && ! -t 0 ]]; then
      PROMPT_FILE=$(mktemp "${TMPDIR:-/tmp}/codex-dispatch-prompt.XXXXXX")
      trap '[[ -z "${PROMPT_FILE:-}" ]] || rm -f "$PROMPT_FILE"' EXIT
      cat > "$PROMPT_FILE"
      PROMPT_PREVIEW=$(LC_ALL=C head -c 300 "$PROMPT_FILE")
    fi

    # "Review-shaped" dispatches get the diff-size cap and the dedup gate:
    # an explicit `codex review`, or an `exec` whose prompt reads as a
    # review/verdict/adversarial ask.
    REVIEW_SHAPED_RE='review|verdict|adversar'
    IS_REVIEW_SHAPED=0
    if [[ "${RUN_ARGS[0]:-}" = "review" ]]; then
      IS_REVIEW_SHAPED=1
    else
      shopt -s nocasematch
      if [[ "${RUN_ARGS[0]:-}" = "exec" ]] && [[ "$PROMPT_PREVIEW" =~ $REVIEW_SHAPED_RE ]]; then
        IS_REVIEW_SHAPED=1
      fi
      shopt -u nocasematch
    fi
    if (( IS_REVIEW_SHAPED )); then
      diff_cap_gate "$RUN_CWD"
      dedup_gate "$RUN_CWD"
    fi

    FINAL_ARGS=("$@")
    [[ -n "$DISPATCH_MODEL" ]] && FINAL_ARGS+=(-c "model=\"$DISPATCH_MODEL\"")
    [[ -n "$DISPATCH_EFFORT" ]] && FINAL_ARGS+=(-c "model_reasoning_effort=\"$DISPATCH_EFFORT\"")

    if [[ "${CODEX_DISPATCH_DRY_RUN:-}" = "1" ]]; then
      printf 'argv: %s\n' codex "${FINAL_ARGS[@]}"
      exit 0
    fi

    STATUS=0
    if [[ -n "$PROMPT_FILE" ]]; then
      codex "${FINAL_ARGS[@]}" < "$PROMPT_FILE" || STATUS=$?
    else
      codex "${FINAL_ARGS[@]}" || STATUS=$?
    fi

    append_ledger "${RUN_ARGS[0]:-run}" "$RUN_CWD" "$STATUS"
    if (( IS_REVIEW_SHAPED )) && (( STATUS == 0 )); then
      record_dedup
    fi
    exit "$STATUS"
    ;;

  *)
    die "unknown command '$cmd' — use: status | run <codex args...> | detach <RESULTS> -- <cmd...> | ledger [N]"
    ;;
esac
