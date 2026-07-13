---
name: ad-attribution
description: Privacy-preserving ad measurement with AdAttributionKit (SKAdNetwork's successor) — install and re-engagement attribution, conversion-value strategy under crowd anonymity, and end-to-end postback testing. Use when running paid acquisition beyond Apple Ads, measuring re-engagement campaigns, designing conversion values, or migrating from SKAdNetwork.
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Ad Attribution (AdAttributionKit)

You can't optimize paid traffic you can't measure. AdAttributionKit is Apple's
privacy-preserving attribution framework — interoperable with SKAdNetwork, and the go-forward
path (it also works in alternative marketplaces). This skill covers the *advertised-app* side:
what an indie running paid campaigns must implement and how to design conversion signals that
survive privacy thresholds.

Note the seam: **Apple Ads attribution uses the AdServices framework, not AdAttributionKit** —
campaigns there are measured in the Apple Ads console (see `app-store/apple-search-ads`). This
skill is for every *other* paid channel (ad networks, social, publishers).

## When This Skill Activates

- Running or planning paid user acquisition outside Apple Ads
- "How do I know which campaign drove installs?" / measuring re-engagement ads
- Designing or debugging conversion values / postbacks
- Migrating from SKAdNetwork (fully interoperable — registered networks need no re-enrollment)

## How it works (the 60-second model)

Ad network signs an ad (compact JWS impression) → publisher app shows it → user installs (or
re-engages) → after a privacy-delayed measurement window, a **postback** with your conversion
info goes to the ad network (and optionally to you). Attribution requires no user tracking;
the price is coarser data, governed by **crowd anonymity**.

## Conversion-value strategy (the part that's actually yours)

- Two granularities: **fine value 0–63** and **coarse low/medium/high**. Low crowd sizes
  downgrade fine → coarse and can trim the 4-digit campaign `source-identifier` to as few as
  its **first 2 digits** — so encode what matters most (campaign family, geo tier) in the
  first two digits, detail in the rest.
- Map values to *revenue-predictive* early behavior (completed onboarding, trial start, first
  purchase), not vanity events. 64 slots go fast; reserve ranges (e.g. 0–15 activation,
  16–47 monetization ladder, 48–63 reserved).
- Update with `updateConversionValue(_:)` / `PostbackUpdate`; set `lockPostback` when the value
  is final to schedule transmission (still privacy-delayed, never instant).
- Re-engagement postbacks are separate from install postbacks: update them independently via
  `conversionTypes` (.install / .reengagement); the **first re-engagement update must land
  within 48 hours**.
- Multiple simultaneous re-engagement campaigns need **conversion tags** (iOS 18.4+): read the
  tag from the re-engagement URL's query items, store it, and pass it in `PostbackUpdate` —
  without a tag, updates hit only the most recent conversion.

## Publisher-side mechanics (if your app also *shows* ads)

- Click-through: `UIEventAttributionView` over the tappable ad + `appImpression.handleTap()`
  within **15 minutes** of creating the impression.
- View-through: `beginView()`/`endView()` on the same instance; **≥2 seconds** on screen to
  count; one open view-through per network per advertised app.
- `SKOverlay` / `SKStoreProductViewController`: attach the impression — they count view on
  present, click on tap.

## Attribution windows & cooldowns (iOS 18.4+ configurability)

- Defaults: **30 days click-through, 1 day view-through** (install ads).
- Override per ad network and interaction type in Info.plist
  (`AdAttributionKitConfigurations` → `AttributionWindows`); you can ignore "view" or "click"
  (not both) per network.
- Set **cooldowns** (`install-cooldown-hours`, `reengagement-cooldown-hours`) so a
  re-engagement tap minutes after an install isn't double-attributed.
- Country-level postback data (iOS 18.4): storefront country at install, gated behind an extra
  crowd-anonymity tier — a bonus signal when volume allows, never guaranteed.
- Overlapping re-engagement conversions require opting in:
  `EligibleForAdAttributionKitOverlappingConversions` = YES in Info.plist.

## Testing — never ship blind

- **Developer Mode → Settings → Developer → Ad Attribution Testing**: removes time
  randomization, shortens all conversion windows, sends postbacks on demand — full end-to-end
  rehearsal in minutes instead of days.
- Point development postbacks at a **separate dev endpoint**, never production: they're signed
  with a different key (`kid`), the network ID is always `development.adattributionkit`, and
  the advertised item ID may be 0 from Xcode.
- ✅ Verify the postback pipeline before spending a dollar. ❌ Debugging attribution *after*
  a live campaign burns budget on unmeasurable installs.

## Checklist

- [ ] Conversion-value map documented (0–63 + coarse fallback + first-2-digit priority)
- [ ] `lockPostback` fired once value is final; re-engagement first update < 48h
- [ ] Conversion tags wired if >1 re-engagement campaign runs at once
- [ ] Cooldowns configured; windows tuned per network where defaults don't fit
- [ ] Dev-endpoint postback rehearsal done in Developer Mode
- [ ] Campaign readout joined with `growth/analytics-interpretation` (source-type funnel) —
      attribution tells you *which ad*, App Analytics tells you *what they did after*

## References

- https://developer.apple.com/documentation/adattributionkit
- https://developer.apple.com/videos/play/wwdc2024/10060/ (Meet AdAttributionKit)
- https://developer.apple.com/videos/play/wwdc2025/221/ (What's new in AdAttributionKit)
- Related skills: `app-store/apple-search-ads` (Apple Ads uses AdServices, not this), `growth/analytics-interpretation`, `growth/store-growth-audit` (P7.3 halo tracking)
