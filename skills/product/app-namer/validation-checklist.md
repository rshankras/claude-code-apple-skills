# Name Validation Gauntlet

Reference for the `app-namer` skill. A clever name is worthless if it's taken, trademarked, or has no home online. Run every finalist through these five checks **before recommending it**. Record each as `available` / `taken` / `conflict` / `unchecked`.

> **Never report a name as "available" you didn't actually verify.** If you can't check something, mark it `unchecked` and tell the user the exact step to run. A false "it's free!" leads to a wasted brand investment.

## 1. App Store Name Availability (the #1 blocker)

App Store app names are **unique across the entire App Store** and assigned first-come.

### How it works
- You reserve a name by **creating the app record in App Store Connect** (you can create the record and reserve the name *without* submitting a build).
- A reserved-but-unused name still blocks everyone else. Apple may reclaim a name not used within a period, and holds names from removed apps for a while before releasing them — so "no app by that name exists today" does **not** guarantee it's free to reserve.
- The name only needs to be unique; you can differentiate with a separator + subtitle (`Pantry:` vs `Pantry`) if the bare word is taken.

### How to check
1. **Exact-name search on the App Store** (WebSearch / App Store) — is there a live app with that exact name? If yes, it's taken.
2. **Definitive check:** the user opens App Store Connect → **Apps → (+) New App** → types the name. ASC immediately says whether it's available to reserve. This is the only authoritative check.

### Action
As soon as a name passes scoring and has no obvious conflict, tell the user to **reserve it in App Store Connect now**. Names disappear; reservation is free and doesn't commit you to shipping.

## 2. Trademark Knockout Search

This is a **knockout search** (catch obvious conflicts), **not legal clearance**. State that plainly.

> ⚠️ Not legal advice. A clean knockout search reduces risk; it does not clear you to file or guarantee no conflict. Consult a trademark attorney before registering a mark or investing heavily in a brand.

### What to search
- **USPTO** — `tmsearch.uspto.gov` for live US marks. Focus on the software classes:
  - **Class 9** — downloadable software / mobile apps
  - **Class 42** — SaaS / software-as-a-service
- **EUIPO** — `euipo.europa.eu` eSearch for EU marks (if targeting Europe)
- **Plain web + App Store search** — an existing well-known brand in your space is a common-law risk even without a registration

### How to read results
| Finding | Verdict |
|---------|---------|
| Identical mark, same/related class (software) | 🔴 Conflict — drop it |
| Confusingly similar mark in software | 🟠 Risk — get attorney input |
| Same word, unrelated class (e.g. a snack brand) | 🟡 Usually OK for software, note it |
| No live marks in software classes | 🟢 Clear knockout — still not legal clearance |

For trademarked *keywords* (vs. names) see `app-store/keyword-optimizer/keyword-criteria.md` → "Trademark Considerations" — the same logic applies to brand terms in your title/subtitle.

## 3. Domain Availability

You want a web home for the app (landing page, support URL, privacy policy host).

### Priority order
1. **`brandname.com`** — ideal but for short words almost always taken
2. **`brandname.app`** — the `.app` TLD is purpose-built for apps, HTTPS-enforced, and far more available. Excellent and increasingly expected for indie apps.
3. **Prefixed `.com`** — `getbrand.com`, `trybrand.com`, `usebrand.com`, `brandapp.com`
4. **Other TLDs** — `.io`, `.co` as fallbacks

### How to check
WebSearch / WebFetch a registrar (e.g. query "is `<name>.app` available domain") or a whois lookup. Mark which exact domain is the recommended buy.

A taken `.com` is **not** a dealbreaker if `.app` or a clean prefixed domain is free — but flag it so the user knows the trade-off.

## 4. Social Handle Availability (nice-to-have)

A consistent handle across platforms helps brand recall but is **not a blocker**.

- Check **X/Twitter, Instagram, and (if relevant) TikTok / Mastodon / Bluesky** for `@brandname`, falling back to `@brandnameapp` or `@getbrandname`.
- A quick way: search each platform, or a multi-platform username checker.
- Record the best consistent handle available; don't kill an otherwise great name over a taken handle.

## 5. Linguistic & Pronounceability Safety

The name ships worldwide and gets spoken to Siri.

- **No unfortunate meanings** in top ASO markets — at minimum spot-check **Chinese, Japanese, German, Spanish, French** (the highest-revenue App Store locales). A name that's fine in English can be a slur, a laugh, or a competitor's word elsewhere.
- **Siri-pronounceable** — "Hey Siri, open ___" should work; avoid respellings and silent letters.
- **Spellable on first hearing** (the radio test) — if users will mistype it, they'll land on a competitor.
- **No homophone collision** with a big app (sounds like Notion, Bear, Things…).

## Validation Summary Table

Fill this in for each finalist before recommending:

```
NAME: Brim
┌────────────────────┬────────────┬──────────────────────────────────────┐
│ Check              │ Status     │ Notes / Action                         │
├────────────────────┼────────────┼──────────────────────────────────────┤
│ App Store name     │ unchecked  │ No live "Brim" tracker found — verify  │
│                    │            │ in ASC New App, reserve if free        │
│ Trademark (Cls 9)  │ 🟢 clear    │ No live software mark in USPTO TESS     │
│ Domain             │ 🟢 .app free │ brim.com taken → buy brim.app           │
│ Social handle      │ 🟡 partial  │ @brim taken → @brimapp available        │
│ Linguistic/Siri    │ 🟢 clear    │ Clean EN/ES/DE/JA; Siri-safe            │
└────────────────────┴────────────┴──────────────────────────────────────┘
VERDICT: Recommend — reserve "Brim" in App Store Connect, buy brim.app.
```

## Go / No-Go Rules

- 🔴 **No-Go** if: App Store name is taken with no workable variant, OR an identical trademark exists in software class.
- 🟠 **Caution** if: confusingly similar trademark, or only awkward domains/handles remain — surface the risk, let the user decide.
- 🟢 **Go** if: name reservable in ASC, clean trademark knockout, a usable domain (.com or .app), Siri-safe and spellable.

When a name clears, the very next action is always: **reserve it in App Store Connect.**
