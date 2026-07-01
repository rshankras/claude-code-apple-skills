# `_shared/asc-api/` — App Store Connect REST helper

Shared foundation for the ASC-automation skills (`app-store/iap-finalizer`, `legal/privacy-publish`, and the TestFlight enabler). It exists because a SwiftShip *skill* is a markdown playbook that orchestrates existing tools — it can't add new endpoints. The `asc-metadata` MCP covers a lot, but **not** IAP price/localization or app privacy/support URLs. `asc.py` fills those gaps by calling the ASC REST API directly with your own key.

> **Not the MCP's key.** The `asc-metadata` MCP holds its credential *inside the server*; a skill can't reach it. `asc.py` uses a **separate `.p8`** you generate and store under `~/.appstoreconnect/`.

## One-time setup (§0)

1. **Generate a key** — App Store Connect ▸ **Users and Access ▸ Integrations ▸ App Store Connect API ▸ Team Keys** ▸ generate with role **App Manager** (Admin only if it must also manage users).
2. **Download** `AuthKey_<KEY_ID>.p8` (downloadable **once**) →
   ```
   ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
   ```
3. **Record IDs** — put `KEY_ID` and `ISSUER_ID` in `~/.appstoreconnect/config` (or export as env):
   ```
   ASC_KEY_ID=XXXXXXXXXX
   ASC_ISSUER_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
   ```
4. **Dependency:** `pip install cryptography`

**Never commit the `.p8`** (or the config). Keep them under `~/.appstoreconnect/` only.

## Usage — safe by default

`asc.py` **prints the request and does not send** unless you add `--apply`. This is the shared `dry-run → show diff → confirm → --apply` convention every skill follows (mirrors the MCP's `dryRun`, and honors "gate outward/ASC writes per-step").

```bash
python3 asc.py GET   /v1/apps
python3 asc.py GET   "/v1/inAppPurchases/<id>/pricePoints?filter[territory]=USA"
python3 asc.py POST  /v1/inAppPurchasePriceSchedules @body.json          # dry-run
python3 asc.py POST  /v1/inAppPurchasePriceSchedules @body.json --apply  # sends
python3 asc.py PATCH /v1/appInfoLocalizations/<id> '{"data":{...}}' --apply
```

Prove it works before trusting it: run any `GET … --apply` (e.g. `/v1/apps`) once — a 200 with your apps confirms the key + JWT are good.

## Caveat for skill authors

**Verify every endpoint/field against the current [App Store Connect API reference](https://developer.apple.com/documentation/appstoreconnectapi) before an `--apply`.** The API evolves; the flows in the dependent skills were captured 2026-07. The helper is deliberately dumb (auth + transport only) — the skills own the request bodies.
