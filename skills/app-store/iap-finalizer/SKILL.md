---
name: iap-finalizer
description: Take a one-time in-app purchase from MISSING_METADATA to READY_TO_SUBMIT in App Store Connect — set its price schedule and localized display name/description (and optional review screenshot) via the ASC REST API. Use at Phase 6 (Pre-Release), after the IAP is built in-app (Phase 4) and its ASC record exists. NOT for subscriptions, and NOT the same as promoted-iap (which displays IAPs in-app).
allowed-tools: [Read, Bash, mcp__asc-metadata__list_iap, mcp__asc-metadata__get_iap, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# IAP Finalizer

Finish a **one-time** in-app purchase on the store side: **price + localization**, the two fields the `asc-metadata` MCP can't set (it exposes only reference name / review note / family-sharing). Moves an IAP from `MISSING_METADATA` → `READY_TO_SUBMIT` so it can ship with the build.

> **This finalizes; it does not define.** The product id, tier, and price *decision* come from Phase 4 (Monetization / StoreKit). The ASC IAP record must already exist (created via the MCP `create_iap` or the ASC UI). This skill sets the metadata on that existing record.

## Where it fits (read the seams)

- **Not Phase 4.** Phase 4 builds the IAP *into the app* (StoreKit 2, paywall) and *decides* the price. This is Phase 6 store-metadata finalization.
- **Price = one source of truth.** Do **not** re-ask the price. **Read it** from the monetization decision in `.planning/` (e.g. `MONETIZATION.md` / `PLAN.md`); only *confirm* it. Re-eliciting risks drift from the paywall/StoreKit price.
- **Not `promoted-iap`.** That generator displays promoted IAPs in-app; this sets ASC price/localization. Different jobs.
- **One-time IAPs only.** Subscriptions are a separate ASC flow (groups/offers) — out of scope here.

## Prerequisites

- `_shared/asc-api/` set up (see its README — key + `~/.appstoreconnect/`).
- Set `ASC="python3 <path to asc.py>"`. `asc.py` lives at `_shared/asc-api/asc.py` under the same `skills/` root as this skill — resolve it **relative to this SKILL.md file's location** (`../../_shared/asc-api/asc.py` from this skill's directory), never relative to the project cwd (skills run with cwd = the user's project). Known install locations:
  - SwiftShip symlink install: `~/.claude/swiftship-skills/_shared/asc-api/asc.py`
  - Copied install: `.claude/skills/_shared/asc-api/asc.py` (project) or `~/.claude/skills/_shared/asc-api/asc.py` (global)
  - Plugin install: resolve from this file's location — the `_shared/` tree ships with the plugin.
- The IAP already exists in ASC. Get its id with the MCP: `list_iap` → pick the product.
- Price decided in Phase 4. Read it from `.planning/` and confirm — don't invent it.

## Flow — dry-run → confirm → apply

1. **Confirm state.** MCP `get_iap` → current state + `productId`. Read the target price + Display Name (≤30) + Description (≤45) from `.planning/`; confirm with the user via `AskUserQuestion` if anything is missing.
2. **Find the price point.**
   ```
   $ASC GET "/v1/inAppPurchases/<IAP_ID>/pricePoints?filter[territory]=USA"
   ```
   Pick the `inAppPurchasePricePoint` id whose `customerPrice` matches the target tier (e.g. 6.99).
3. **Set the price** (one-time IAPs use *price schedules*):
   ```
   $ASC POST /v1/inAppPurchasePriceSchedules @price.json          # dry-run: review the body
   $ASC POST /v1/inAppPurchasePriceSchedules @price.json --apply  # after you confirm
   ```
   Body: `data` relationships `inAppPurchase`→{IAP_ID}, `baseTerritory`→USA, `manualPrices`→[new `inAppPurchasePrices`]; `included` a new `inAppPurchasePrices` referencing the price point with `startDate: null` (="now").
4. **Set the localization:**
   ```
   $ASC POST /v1/inAppPurchaseLocalizations '{"data":{"type":"inAppPurchaseLocalizations","attributes":{"locale":"en-US","name":"<=30","description":"<=45"},"relationships":{"inAppPurchase":{"data":{"type":"inAppPurchases","id":"<IAP_ID>"}}}}}' --apply
   ```
   PATCH the existing localization id instead if one already exists.
5. **Review screenshot (optional):** `POST /v1/inAppPurchaseAppStoreReviewScreenshots` — the 3-step ASC upload (reserve → upload bytes → commit).
6. **Verify:** MCP `get_iap` → state no longer `MISSING_METADATA`.

## Done

- IAP priced + localized in ASC; state advanced; ready to submit with the build.

## Caveats

- **Verify each endpoint/field against the current [ASC API reference](https://developer.apple.com/documentation/appstoreconnectapi) before `--apply`** (captured 2026-07).
- Every write is **dry-run first** — show the body, confirm, then `--apply`. Never `--apply` a price the user hasn't seen.
- One-time IAPs only. Subscriptions → the MCP `create_subscription*` tools + a separate flow.
