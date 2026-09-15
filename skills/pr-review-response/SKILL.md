---
name: pr-review-response
description: >-
  Respond to a PR review the right way: ONE point-by-point comment mirroring
  the reviewer's structure — every raised item gets a disposition (FIXED /
  DEFERRED / DISCLOSED / REFUTED), its exact location, and its evidence. Use
  for: "respond to the review", "reply to reviewer", "address review
  comments", or any time fixes have landed after a human or bot left findings
  on a PR.
---

# PR review response — the standard

When a reviewer (human or bot) leaves findings and fixes have landed, the response is ONE
comment that answers EVERY point they raised, in THEIR order. Never a summary blob, never
"all fixed", never a restatement of the PR body.

## Structure

1. **Header**: the fix anchor (`sha`, parent sha) + one line on how the fixes were verified
   (independent re-verification, mutation protocol, suite counts come at the end).
2. **Mirror the review's own sectioning** (their P1s / P2s / ledgers / teeth / NITs, their
   numbering). For each item:
   - Name the finding in their words (short quote or their id).
   - **Disposition**, bolded: FIXED / DEFERRED (why + where it's tracked) / DISCLOSED
     (honest residual, stated plainly, never folded into a done-claim) / REFUTED (with the
     reproduction evidence that failed).
   - The exact change location (`file:line`) and the proof: test name, mutation result,
     probe output — claims name what was verified.
   - If the reviewer supplied a fix line: say whether it was implemented verbatim; if
     deviated, say why.
3. **Their mutation survivors / teeth** (if the review used a mutation-testing lens): each
   one addressed by name — killed (which pin) or confirmed-by-design (with the independent
   re-verification).
4. **Test-integrity disclosure**: every touched pre-existing test named with its
   justification; assertions strengthen-only; say so explicitly.
5. **Evidence block** at the end: full-suite counts at the anchor, mutation totals including
   by-design survivors, and what external verification is queued (staging runs, live checks).
6. **NITs**: applied, or explicitly acknowledged-not-touched with an offer to sweep.

## Anti-patterns (each of these costs a review round)

- A summary comment that compresses findings into themes — the reviewer re-derives the
  mapping, and unanswered items read as ignored.
- "All fixed" without per-item evidence.
- Silently claiming a partial fix (the residual ALWAYS gets its own sentence).
- Deferring an item without saying where it now lives.
- Multiple scattered replies instead of one structured comment — the reviewer has to
  reassemble the response themselves, and it's easy to miss which items got answered.

## Comment template

```
## Response to review @ <fix-sha> (parent <parent-sha>)

Verified by: <how — independent re-run, mutation pass, manual repro>

### <reviewer's section 1 name, e.g. "P1s">

**1. <finding, in their words or id>** — **FIXED** at `path/to/file:123`.
   Evidence: `test_name` now passes; <command/output that proves it>.

**2. <finding>** — **DEFERRED**. Tracked at <issue/ticket>. Why now, not here: <reason>.

**3. <finding>** — **DISCLOSED**. <what remains true after the fix, stated plainly>.

**4. <finding>** — **REFUTED**. Reproduction: <what was run>, result: <output showing the
   claim doesn't hold>.

### NITs

- <nit> — applied at `file:line`.
- <nit> — acknowledged, not touched. Offer to sweep in a follow-up.

### Evidence

Full suite at <sha>: <N passed / 0 failed>. Mutation: <N killed / N by-design survivors>.
Queued: <staging/live checks still pending>.
```

Every raised item appears exactly once, in this comment, in the reviewer's own order.
