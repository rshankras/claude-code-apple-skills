---
name: originality-check
description: Guideline-4.3 anti-spam / originality gate — score whether an app (and each portfolio addition) is meaningfully distinct in function, content, and metadata before you invest or submit. Use at validation/new-app time and again before submission. Protects the whole developer account from 4.3 (spam/duplicate) rejections. NOT rejection-handler (that works an existing rejection) and NOT competitive-analysis (that positions in the market).
allowed-tools: [Read, Write, WebSearch, Glob, Grep, AskUserQuestion, mcp__asc-metadata__list_apps, mcp__asc-metadata__get_metadata]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Originality Check

Decide, with evidence, whether an app is *distinct enough to exist* — before you build it or submit it.

> At portfolio scale, shipping many similar small apps is exactly what triggers **Guideline 4.3
> (spam / duplicate)**. One 4.3 is a warning; repeated 4.3s put the **whole account** at risk. This
> is the go/no-go distinctness gate that keeps that from happening.

## Where it fits (read the seams)

- **Not `rejection-handler`.** That works a rejection you *already have*. This is upstream — it
  prevents the 4.3 by catching sameness before you ship.
- **Not `competitive-analysis` / `market-research`.** Those size demand and position you in the
  market. This judges *distinctness* (function + content + metadata) vs your own portfolio and vs
  near-identical competitors — a spam risk, not a demand question.
- **Two moments to run it:** at `validate` / `new-app` (don't build a dup) and before `submit`
  (don't trip 4.3). Also periodically across the portfolio (internal cannibalization / template-sameness).

## Prerequisites

- The app idea or a shipped app to evaluate (name, one-line function, target metadata).
- Optional: `.planning/VALIDATION.md` (competitor + market data). If missing/stale, gather fresh
  via WebSearch or the `product/competitive-analysis` skill.
- Optional ASC access to read the developer's existing portfolio (`list_apps` / `get_metadata`).

## Flow

1. **Internal check (your own portfolio).** `list_apps` → for each shipped app read its positioning
   (`get_metadata`). Does the candidate overlap one you already ship in **function**, **code
   template**, or **metadata**? Two apps that differ only in theme/reskin = 4.3 risk.
2. **External check (the market).** Read `VALIDATION.md` if present; otherwise `WebSearch` for close
   look-alikes. Judge: is the core function a thin reskin of an existing app, or a genuine wedge?
3. **Distinctness scorecard.** Score each dimension *meaningful difference vs cosmetic*, and flag any
   that is only skin-deep:

   | Dimension | Distinct if… |
   |---|---|
   | **Function** | it does something materially different, not a template swap |
   | **Content / data** | unique data or content, not a generic wrapper |
   | **Metadata** | name / keywords / screenshots not near-identical to siblings or competitors |
   | **UX / value** | a real reason a user picks *this* one |

4. **Verdict + remedy.**
   - **Distinct** → proceed.
   - **Borderline** → give concrete ways to differentiate (merge sibling apps into one configurable
     app, add the unique wedge, or drop it); if approved, name the specific wedge that MUST be built
     to clear 4.3.
   - **Duplicate** → recommend not shipping; if several thin apps already exist, recommend
     consolidating into one strong app (better for ranking *and* review).
5. **Record.** Write the verdict + reasoning to `.planning/` (VALIDATION or STATE). For a
   borderline-approved app, record the wedge as a build requirement so `plan`/`build` deliver it.

## Done

- A written verdict (distinct / borderline+wedge / duplicate) with per-dimension reasoning, and —
  if borderline — the specific differentiation that must ship before submission.

## Caveats

- **Cosmetic theming ≠ differentiation.** Apple judges function + metadata similarity, not your
  intent. Score honestly.
- **Protect the account.** When in doubt between "borderline ship" and "consolidate," prefer one
  strong app over several thin ones.
- Guideline numbers/text drift — confirm current 4.3 wording at the
  [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (captured 2026-07).
