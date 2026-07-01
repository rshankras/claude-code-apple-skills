#!/usr/bin/env python3
"""asc.py - minimal App Store Connect REST helper (ES256 JWT auth).

SAFE BY DEFAULT: prints the request and does NOT send unless you pass --apply.
Every SwiftShip skill that uses this runs dry-run -> show diff -> confirm -> --apply.

One-time setup (see README.md):
  1. App Store Connect > Users and Access > Integrations > App Store Connect API
     > Team Keys > generate a key with role "App Manager".
  2. Download AuthKey_<KEY_ID>.p8 (one download only) to
     ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
  3. export ASC_KEY_ID=... ASC_ISSUER_ID=...   (or put them in ~/.appstoreconnect/config)

Usage:
  asc.py GET   /v1/apps
  asc.py GET   "/v1/inAppPurchases/<id>/pricePoints?filter[territory]=USA"
  asc.py POST  /v1/inAppPurchasePriceSchedules @body.json          # dry-run: prints only
  asc.py POST  /v1/inAppPurchasePriceSchedules @body.json --apply  # actually sends
  asc.py PATCH /v1/appInfoLocalizations/<id> '{"data":{...}}' --apply

Dependency: cryptography  ->  pip install cryptography
"""
import sys, os, json, time, base64, urllib.request, urllib.error

BASE = "https://api.appstoreconnect.apple.com"
CONFIG = os.path.expanduser("~/.appstoreconnect/config")


def _b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=")


def _load_config():
    key_id = os.environ.get("ASC_KEY_ID")
    issuer = os.environ.get("ASC_ISSUER_ID")
    if (not key_id or not issuer) and os.path.exists(CONFIG):
        for line in open(CONFIG):
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            k, v = (x.strip() for x in line.split("=", 1))
            if k == "ASC_KEY_ID" and not key_id:
                key_id = v
            if k == "ASC_ISSUER_ID" and not issuer:
                issuer = v
    if not key_id or not issuer:
        sys.exit("Missing ASC_KEY_ID / ASC_ISSUER_ID (env or ~/.appstoreconnect/config).")
    return key_id, issuer


def _make_token(key_id, issuer):
    try:
        from cryptography.hazmat.primitives.serialization import load_pem_private_key
        from cryptography.hazmat.primitives.asymmetric import ec, utils
        from cryptography.hazmat.primitives import hashes
    except ImportError:
        sys.exit("Missing dependency: pip install cryptography")
    p8 = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8")
    if not os.path.exists(p8):
        sys.exit(f"Private key not found: {p8}")
    key = load_pem_private_key(open(p8, "rb").read(), password=None)
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {"iss": issuer, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    signing_input = (
        _b64url(json.dumps(header, separators=(",", ":")).encode())
        + b"."
        + _b64url(json.dumps(payload, separators=(",", ":")).encode())
    )
    der = key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
    r, s = utils.decode_dss_signature(der)
    raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")
    return (signing_input + b"." + _b64url(raw)).decode()


def main():
    args = sys.argv[1:]
    apply = "--apply" in args
    args = [a for a in args if a != "--apply"]
    if len(args) < 2:
        sys.exit(__doc__)
    method, path = args[0].upper(), args[1]
    body = None
    if len(args) >= 3:
        raw = args[2]
        body = open(os.path.expanduser(raw[1:])).read() if raw.startswith("@") else raw
    url = BASE + path if path.startswith("/") else path
    print(f"# {method} {url}")
    if body:
        print(body)
    if not apply:
        print("# DRY-RUN (default) - not sent. Re-run with --apply to send.")
        return
    key_id, issuer = _load_config()
    token = _make_token(key_id, issuer)
    req = urllib.request.Request(url, data=body.encode() if body else None, method=method)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            print(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}", file=sys.stderr)
        print(e.read().decode(), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
