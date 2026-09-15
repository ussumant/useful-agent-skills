#!/usr/bin/env bash
# Coverage for the codex-dispatch cost gates. Uses a fake `codex` binary and
# CODEX_DISPATCH_SKIP_AUTH=1 — never touches a real Codex account or bills tokens.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="$SCRIPT_DIR/dispatch.sh"
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/codex-dispatch-selftest.XXXXXX")
TEST_HOME="$TEST_DIR/home"
REPO="$TEST_DIR/repo"
FAKE_BIN="$TEST_DIR/bin"
FAILURES=0

trap 'rm -rf "$TEST_DIR"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; FAILURES=1; }

mkdir -p "$TEST_HOME" "$FAKE_BIN"
cat > "$FAKE_BIN/codex" <<'EOF'
#!/bin/bash
echo "FAKE-CODEX-CALLED $*"
exit 0
EOF
chmod +x "$FAKE_BIN/codex"

run_dispatch() {
  local prompt=$1
  shift
  local extra_env=("$@")
  if LAST_OUTPUT=$(printf '%s' "$prompt" | env \
    HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" \
    CODEX_DISPATCH_HOME="$TEST_HOME/.codex-dispatch" CODEX_DISPATCH_SKIP_AUTH=1 \
    "${extra_env[@]}" \
    "$WRAPPER" run exec -C "$REPO" -s read-only 2>&1); then
    LAST_STATUS=0
  else
    LAST_STATUS=$?
  fi
}

git init -q "$REPO"
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name test
git -C "$REPO" symbolic-ref HEAD refs/heads/main
echo "line" > "$REPO/base.txt"
git -C "$REPO" add base.txt
git -C "$REPO" commit -qm base

# --- diff cap gate ---
git -C "$REPO" checkout -qb feature
seq 1 30 > "$REPO/small.txt"
git -C "$REPO" add small.txt
git -C "$REPO" commit -qm "small change"
run_dispatch "Review this diff" CODEX_DISPATCH_DIFF_CAP=1500 CODEX_DISPATCH_BASE_REF=main
if [[ "$LAST_STATUS" -eq 0 ]] && grep -Fq 'FAKE-CODEX-CALLED' <<<"$LAST_OUTPUT"; then
  pass 'a small diff under cap → dispatches'
else
  fail 'a small diff under cap → dispatches'
fi

seq 1 2000 > "$REPO/big.txt"
git -C "$REPO" add big.txt
git -C "$REPO" commit -qm "big change"
run_dispatch "Review this diff" CODEX_DISPATCH_DIFF_CAP=1500 CODEX_DISPATCH_BASE_REF=main
if [[ "$LAST_STATUS" -eq 3 ]] && grep -Fq 'diff cap' <<<"$LAST_OUTPUT"; then
  pass 'b diff over cap → exit 3'
else
  fail 'b diff over cap → exit 3'
fi

run_dispatch "Review this diff" CODEX_DISPATCH_DIFF_CAP=1500 CODEX_DISPATCH_BASE_REF=main CODEX_DISPATCH_DIFF_OVERRIDE=1
if [[ "$LAST_STATUS" -eq 0 ]] && grep -Fq 'FAKE-CODEX-CALLED' <<<"$LAST_OUTPUT"; then
  pass 'c diff over cap with override → dispatches'
else
  fail 'c diff over cap with override → dispatches'
fi

# --- dedup gate (one review per push) ---
git -C "$REPO" checkout -qb dedup-branch main
seq 1 5 > "$REPO/dedup.txt"
git -C "$REPO" add dedup.txt
git -C "$REPO" commit -qm "dedup change"
run_dispatch "Review this diff" CODEX_DISPATCH_BASE_REF=main
if [[ "$LAST_STATUS" -eq 0 ]] && grep -Fq 'FAKE-CODEX-CALLED' <<<"$LAST_OUTPUT"; then
  pass 'd first review of a SHA → dispatches'
else
  fail 'd first review of a SHA → dispatches'
fi
run_dispatch "Review this diff" CODEX_DISPATCH_BASE_REF=main
if [[ "$LAST_STATUS" -eq 3 ]] && grep -Fq 'one-review-per-push' <<<"$LAST_OUTPUT"; then
  pass 'e re-review of same SHA → exit 3'
else
  fail 'e re-review of same SHA → exit 3'
fi
run_dispatch "Review this diff" CODEX_DISPATCH_BASE_REF=main CODEX_DISPATCH_DEDUP_OVERRIDE=1
if [[ "$LAST_STATUS" -eq 0 ]] && grep -Fq 'FAKE-CODEX-CALLED' <<<"$LAST_OUTPUT"; then
  pass 'f re-review with override → dispatches'
else
  fail 'f re-review with override → dispatches'
fi

# --- non-review prompts skip both gates regardless of diff size ---
run_dispatch "Plain build prompt, add a helper function" CODEX_DISPATCH_DIFF_CAP=1
if [[ "$LAST_STATUS" -eq 0 ]] && grep -Fq 'FAKE-CODEX-CALLED' <<<"$LAST_OUTPUT"; then
  pass 'g non-review prompt ignores diff cap → dispatches'
else
  fail 'g non-review prompt ignores diff cap → dispatches'
fi

# --- dry run prints argv, never calls codex ---
if LAST_OUTPUT=$(printf 'Plain prompt' | env \
  HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" \
  CODEX_DISPATCH_HOME="$TEST_HOME/.codex-dispatch" CODEX_DISPATCH_SKIP_AUTH=1 \
  CODEX_DISPATCH_MODEL=example-model CODEX_DISPATCH_EFFORT=medium CODEX_DISPATCH_DRY_RUN=1 \
  "$WRAPPER" run exec -C "$REPO" -s read-only 2>&1); then
  LAST_STATUS=0
else
  LAST_STATUS=$?
fi
if [[ "$LAST_STATUS" -eq 0 ]] && grep -Fq 'model="example-model"' <<<"$LAST_OUTPUT" \
  && ! grep -Fq 'FAKE-CODEX-CALLED' <<<"$LAST_OUTPUT"; then
  pass 'h dry run prints argv with pinned model, never calls codex'
else
  fail 'h dry run prints argv with pinned model, never calls codex'
fi

exit "$FAILURES"
