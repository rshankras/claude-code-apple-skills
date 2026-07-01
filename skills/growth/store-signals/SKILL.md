---
name: store-signals
description: Close the post-launch loop — turn a live app's App Store signals (reviews, analytics, sales, crashes, listing conversion) into a metric-tagged backlog for the next version, AND verify whether last cycle's changes moved the metric they promised to move. Read-only on App Store Connect; every change is surfaced and routed to another command, never auto-applied. Use before planning the next version, on a monthly cadence, or ~1-2 weeks after shipping to check if a change worked.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion, mcp__asc-metadata__list_apps, mcp__asc-metadata__list_reviews, mcp__asc-metadata__get_review, mcp__asc-metadata__get_analytics_report, mcp__asc-metadata__setup_analytics_reports, mcp__asc-metadata__get_sales_report, mcp__asc-metadata__get_diagnostics, mcp__asc-metadata__get_perf_metrics, mcp__asc-metadata__list_beta_feedback_crashes, mcp__asc-metadata__get_metadata]
---

# Store Signals

Pull what the *shipped* app is actually telling you and convert it into the next backlog — then
verify whether last cycle's bets paid off.

> This is the missing arc that turns build → ship into a **loop**:
> `ship → MEASURE → DIAGNOSE → next PLAN → build → ship → measure again…`
> The ledger (`SIGNALS.md`) is what makes it a loop and not a monthly report.

## Where it fits (read the seams)

- **Not `analytics-interpretation`.** That *interprets* a metric you hand it (is 14% D7 good?). This
  is the end-to-end operate loop: gather every signal → cluster → diagnose → **write a metric-tagged
  backlog** → **close last cycle's hypotheses**. It *uses* analytics-interpretation's benchmarks.
- **Read-only on ASC.** Never responds to reviews, never mutates metadata/pricing. It surfaces, gates
  on explicit OK, and routes the change to the right command (`next-version`, `bugfix`, `metadata`).
- **Feeds planning.** Output is a dated backlog appended to `ROADMAP.md` + rows in `SIGNALS.md`,
  consumed by `/apple:next-version` / `/apple:release`.

## Prerequisites

- A live (or TestFlight) app; resolve its `appId` from `.planning/STATE.md`, else `list_apps` + confirm.
- `.planning/` context: `STATE.md`, `APP.md`, `POSITIONING.md` (job-to-be-done + guardrails).
- `.planning/SIGNALS.md` if present — the OPEN hypotheses from prior runs (each with a target metric,
  recorded baseline, and "check-after" date). See **signals-ledger.md** for the ledger + backlog formats.

## Flow

1. **Load prior hypotheses.** Read `SIGNALS.md` → the OPEN rows to verify in step 5.
2. **Pull the signals (read-only), this period vs trailing:**
   - **Reviews / ratings** — `list_reviews` (recent, lowest-star first; flag unanswered), `get_review` for detail.
   - **Analytics** — `get_analytics_report`: retention, funnel/conversion, acquisition, impression→download.
     No report configured yet → `setup_analytics_reports` and note "retention/funnel lands next cycle."
   - **Sales** — `get_sales_report`: proceeds/units vs trailing 7/30-day.
   - **Stability / perf** — `get_diagnostics` (crash/hang signatures) + `get_perf_metrics` (launch, memory, energy).
   - **Beta** — `list_beta_feedback_crashes` if in TestFlight.
   - **Listing** — `get_metadata` to spot ASO conversion problems against current copy.
3. **Normalize & cluster.** Dedupe reviews into recurring themes (requests / complaints / praise) with
   frequency; attach magnitude (users / revenue / retention implicated). Weight by **frequency ×
   revenue impact**, not by how loud one reviewer is.
4. **Diagnose, filter, prioritize.** Map each cluster to the core metric it moves (rating · D7 · Pro
   conversion · crash-free rate · ASO conversion · proceeds); score **impact × confidence ÷ effort**.
   **Strategy filter:** cross-check `POSITIONING.md` — on-strategy → backlog; off-strategy → list under
   **"Declined (why)"** (never silently drop, never silently build). Carry the app's guardrails forward.
   Small-N (new app): say so, lean on qualitative reviews, flag low confidence.
5. **Close the prior loop.** For each OPEN hypothesis whose change shipped and whose "check-after" date
   passed: compare the target metric now vs its baseline → **WIN / REGRESSION / NEUTRAL**. WIN → resolve;
   REGRESSION → open a revert/rethink task; NEUTRAL → keep watching or retire.
6. **Write the backlog.** Append a dated, metric-tagged section to `ROADMAP.md` and update `SIGNALS.md`
   (one row per hypothesis; formats in **signals-ledger.md**). Then output a ranked digest (top 3-5
   "what's hurting most, why, the proposed move"), the loop-closure results, and a suggested next
   command (`/apple:next-version`, `/apple:bugfix` for a hot crash, `/apple:metadata` for an ASO fix).

## Portfolio mode

With no single app (or `--portfolio`): run steps 2-4 across every app in `list_apps`, then rank which
app to invest in next — biggest fixable revenue/retention/rating gap first (pairs with
`portfolio-health-monitor`). Output one line per app + the single highest-ROI move overall.

## Done

- A ranked cited digest, the WIN/REGRESSION/NEUTRAL loop-closure for last cycle, and a metric-tagged
  backlog written to `ROADMAP.md` + `SIGNALS.md`, with a routed next command.

## Caveats

- **Read-only on ASC** — never auto-apply pricing, metadata, or review responses; surface → gate → route.
- **Evidence over vibes** — every backlog item cites its signal + magnitude; the loudest reviewer is
  not the roadmap.
- **Always verify last cycle (step 5) before planning the next** — that closure is the whole point.
- Apple delivers analytics on its own schedule; a freshly configured report is empty until next cycle.
