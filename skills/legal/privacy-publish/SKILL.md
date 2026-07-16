---
name: privacy-publish
description: Turn drafted legal docs (privacy policy, terms) into hosted pages and set the App Store Connect Privacy Policy / Support / Marketing URLs via the ASC REST API. Use at Phase 6 / submission, after legal drafts exist. The App Privacy "nutrition label" stays manual (Apple exposes no API) — this prints the exact answers to click.
allowed-tools: [Read, Bash, AskUserQuestion, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__read_page]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Privacy Publish

Close the "hosted legal pages + ASC URLs" gap: render `.planning/legal/{privacy,terms}.md` → host them → PATCH the Privacy/Support URLs onto the App Store version. The one thing with no API — the **App Privacy nutrition label** — is handed off as a precise checklist.

> Depends on the user's web infra, so **ask once, remember**. Hosting choice is theirs; the ASC URL-setting is the automatable part.

## Prerequisites

- Legal drafts exist: `.planning/legal/privacy.md`, `.planning/legal/terms.md` (from `legal/privacy-policy`).
- `_shared/asc-api/` set up (README).
- Set `ASC="python3 <path to asc.py>"` — resolve `asc.py` **relative to this SKILL.md file's location** (`../../_shared/asc-api/asc.py`), never the project cwd. Known install locations:
  - SwiftShip symlink install: `~/.claude/swiftship-skills/_shared/asc-api/asc.py`
  - Copied install: `.claude/skills/_shared/asc-api/asc.py` (project) or `~/.claude/skills/_shared/asc-api/asc.py` (global)
  - Plugin install: resolve from this file's location — the `_shared/` tree ships with the plugin.
- The app has a current editable App Store version + an en-US `appInfoLocalization` and `appStoreVersionLocalization` (get their ids first).

## Flow — dry-run → confirm → apply

1. **Render.** Markdown → minimal self-contained HTML (or keep `.md` if the host renders it).
2. **Publish** (pick per the user's infra — `AskUserQuestion` once, then remember in `.planning/`):
   - **git static site** — commit + push to the pages repo/branch.
   - **WordPress** — `POST /wp-json/wp/v2/pages` with an application password.
   - **Netlify / S3 / other** — the host's CLI.
   - **Browser fallback** — drive the CMS with `claude-in-chrome` (detect → preview → confirm → act → fall back, per `TOOL-HANDOFF.md`).
   - **Confirm both URLs resolve (HTTP 200)** before touching ASC.
3. **Set the ASC URLs** (REST — dry-run, confirm, then `--apply`):
   - **Privacy Policy URL** → `appInfoLocalizations` (`privacyPolicyUrl`):
     ```
     $ASC PATCH /v1/appInfoLocalizations/<id> '{"data":{"type":"appInfoLocalizations","id":"<id>","attributes":{"privacyPolicyUrl":"https://…/privacy"}}}' --apply
     ```
   - **Support / Marketing URL** → `appStoreVersionLocalizations` (`supportUrl`, `marketingUrl`) — PATCH the current version's en-US localization id.
4. **Nutrition label (manual — no API).** Emit a checklist matching `Sources/PrivacyInfo.xcprivacy` (e.g. *Data Not Collected*, no tracking) for the user to click in ASC ▸ App Privacy. Do not claim this step is automated.

## Done

- Legal pages live + resolving; Privacy/Support URLs set via API; nutrition-label checklist handed off.

## Caveats

- **Verify each endpoint/field against the current [ASC API reference](https://developer.apple.com/documentation/appstoreconnectapi) before `--apply`** (captured 2026-07).
- Confirm URLs return 200 *before* setting them in ASC — a dead Privacy URL is a common rejection (Guideline 5.1.1).
- The nutrition label and some age-rating specifics have **no public API** — those remain ASC-UI/manual by design.
