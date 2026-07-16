---
name: web-presence
description: The discovery surfaces outside the App Store app — your apps.apple.com product page ranking on Google, an owned landing page with a Smart App Banner, and the deal-site ecosystem that auto-amplifies price drops. Use when building a landing page, improving Google visibility for an app, planning a price-drop promotion, or auditing off-store discovery.
allowed-tools: [Read, Write, Edit, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Web Presence

Every app has a public web page at `apps.apple.com` that ranks in Google — most developers never
work that surface. Pair it with an owned landing page and the deal-site ecosystem and the open
web becomes a free acquisition channel that compounds with everything on-store.

## When This Skill Activates

- "Make my app findable on Google" / no results for the app's own name
- Building or reviewing a product landing page
- Planning a temporary price drop or sale
- The store-growth audit flags P6.6 (web presence) or P7.5 (deal sites)

## Surface 1: The apps.apple.com page is a Google citizen

Your store listing is crawlable, indexable web content. Its Google snippet is built from your
**app name, subtitle, and description opening** — one more reason the first description paragraph
must be benefit-led plain language (see `app-store/app-description-writer`).

- ✅ Search your app's name + category terms on Google periodically; if the store page doesn't
  rank for your own brand, something is wrong (usually a generic name — see `product/app-namer`).
- ✅ Ratings, price, and In-App Purchase labels appear in the snippet — per-storefront ratings
  mechanics apply (`app-store/ratings-mechanics`).
- ❌ Treating the store URL as un-shareable internal plumbing. It's often your best-ranking page;
  link to it from everywhere (with `?pt=` provider token for attribution where you need source data).

## Surface 2: An owned landing page + Smart App Banner

One page, one job: convert a web visitor into a store visitor.

- Structure: name + one-line promise → 2–3 screenshots or a short capture → social proof →
  a prominent **Download on the App Store** badge (Apple's official artwork, linked with your
  attribution token).
- **Smart App Banner** — one meta tag; Safari renders a native install/open banner:

  ```html
  <meta name="apple-itunes-app" content="app-id=YOUR_APP_ID, app-argument=https://yourapp.com/from-web">
  ```

  ✅ The banner shows **Open** for installed users — deep-linking into the app, down to specific
  in-app content via `app-argument` — and **View** for everyone else, opening the App Store in
  one tap. ❌ Custom "download our app" interstitials — Safari users get the
  native banner for free, and interstitials tank your Google page experience.
- **App Store Marketing Tools** (tools.applemediaservices.com) generate short links, QR codes,
  and localized badge assets — use them for referral campaigns and offline/print placements
  instead of hand-rolling links.
- The landing page is also where pre-launch waitlists live (TestFlight public link — see
  `product/beta-testing`) and where press/link-in-bio traffic should land, because you can
  measure it before it enters the store funnel.
- App Clips can front the landing page with an instant experience (`generators/app-clip`).

## Surface 3: The deal-site ecosystem

Aggregators and deal communities scrape App Store price drops automatically — you don't submit
anything, you just drop the price and the ecosystem notices.

The mechanic: temporary price drop → aggregators list it → download spike → **chart climb** →
charts drive organic downloads that outlive the sale. Velocity is the product; the discounted
revenue is the cost of the campaign.

- ✅ Drop meaningfully (50%+ or free-for-a-day reads as a deal; 10% doesn't scrape well).
- ✅ Time drops to compound: with an in-app event, a seasonal moment, or the announced On-Sale
  badge surface (see `generators/in-app-events`), and have the next release ready so climbers
  land on a fresh listing.
- ✅ Prompt for ratings during the spike window — sale users rate too, and the count sticks
  after prices recover.
- ❌ Permanent-discount theater (always "90% off") — scrapers and users both learn to ignore it,
  and review teams notice manipulated anchor pricing.
- ❌ Dropping the price of a subscription app's *download* — deal sites move paid-upfront apps;
  subscription apps should use offer codes instead (`generators/offer-codes-setup`).

## Output Format

Audit report:

```
Google: brand query rank · store-page snippet quality (name/subtitle/desc opener)
Landing page: live? banner tag? attribution token? waitlist path?
Deal readiness: pricing model compatible? last drop + result? next planned window?
```

Each gap routed: copy fixes → `app-store/app-description-writer`; page build → this skill;
price-drop plan → this skill + `monetization` pricing.

## References

- https://developer.apple.com/documentation/webkit/promoting-apps-with-smart-app-banners
- https://developer.apple.com/app-store/marketing/guidelines/
- https://tools.applemediaservices.com/ (official badges & link builder)
- Related skills: `app-store/app-description-writer`, `generators/app-clip`, `product/beta-testing`, `generators/offer-codes-setup`, `growth/store-growth-audit`
