# Signals Ledger & Backlog Formats

Reference formats for `store-signals`. `SIGNALS.md` is the durable **ledger** (one row per
hypothesis, survives across cycles); the **backlog** section is appended to `ROADMAP.md` each run.

## `.planning/SIGNALS.md` — the hypothesis ledger

Step 1 reads it, step 5 resolves the OPEN rows, step 6 appends new ones. Each row is one testable bet.

```markdown
# Signals Ledger

| id | signal (evidence) | hypothesis | target metric | baseline | status | shipped-in | check-after |
|----|-------------------|------------|---------------|----------|--------|------------|-------------|
| S1 | 6/40 reviews ask "team mode" | team mode gives repeat reason to return | D7 retention | 14% | open | — | — |
| S2 | crash sig `-[Settings]` 4.1% sessions | fix settings crash | crash-free rate | 95.9% | shipped | v1.3 | 2026-07-15 |
| S3 | TTR 3.2% (poor) | bolder icon lifts tap-through | impression→download | 3.2% | win | v1.3 | 2026-07-01 |
```

- **status:** `open` (identified, not yet built) · `shipped` (change is live, awaiting check-after) ·
  `win` / `regression` / `neutral` (verified in a later cycle) · `retired` (dropped).
- **baseline:** the metric value recorded *at the time the hypothesis was written* — never overwrite it;
  step 5 compares "now" against this frozen number.
- **check-after:** absolute date (~+14d post-ship) when the metric is expected to have moved.

## Backlog section appended to `ROADMAP.md`

Every item carries the fields below so `next-version` can plan against evidence, not intuition.

```markdown
## Backlog from store signals — <YYYY-MM-DD>

### <item title>
- **signal:** 6 reviews request "team/bracket mode"
- **evidence:** 6 of last 40 reviews; 4.6★ but 3 name it explicitly
- **type:** feature | bug | ASO | pricing | retention
- **hypothesis:** team mode lifts rating + D7 by giving a repeat-event reason to return
- **target metric + baseline:** D7 retention (now 14%); rating (now 4.6)
- **effort:** S | M | L
- **score:** impact × confidence ÷ effort
- **check-after:** +14d post-ship

### Declined (off-strategy / guardrail)
- <request> — declined because <reason vs POSITIONING.md / guardrail>
```

## Loop-closure block (step 5 output)

```markdown
## Loop closure — <YYYY-MM-DD>
| id | shipped-in | metric | baseline → now | verdict | action |
|----|------------|--------|----------------|---------|--------|
| S2 | v1.3 | crash-free rate | 95.9% → 99.4% | WIN | mark resolved |
| S3 | v1.3 | impression→download | 3.2% → 3.1% | NEUTRAL | keep watching |
```

Verdict rule of thumb (see `analytics-interpretation` for per-metric benchmarks): < 3pp move on a
retention/conversion metric ≈ NEUTRAL (noise); a clear move in the wrong direction = REGRESSION →
open a revert/rethink task.
