#!/bin/bash

# Marketplace compatibility tripwire — no plugin-entry keys that older
# Claude Code clients hard-reject.
# History: marketplace.json used `displayName` — a documented field, but one
# that requires Claude Code >= 2.1.143. Older clients strict-parse the
# manifest and fail the ENTIRE `/plugin marketplace add` with
# 'Unrecognized key: "displayName"' (issue #49) — one cosmetic field made
# the marketplace uninstallable for them. CI's `claude plugin validate`
# runs the *latest* CLI, so it can never catch a key that only previous
# client generations reject; this grep can.
#
# Rule: marketplace.json sticks to plugin-entry keys every client
# understands. The keys below are documented but min-versioned — re-add one
# only after consciously deciding the compat floor (and update this list +
# the docs' min-version notes).
#
# Usage:  ./scripts/check-marketplace-compat.sh              # scan manifest
#         ./scripts/check-marketplace-compat.sh --self-test  # embedded fixtures
# Exit:   0 = clean, 1 = min-versioned key found (or self-test failure)

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR" || exit 1

# Documented marketplace plugin-entry keys with a min-version requirement
# (per code.claude.com/docs/en/plugin-marketplaces):
#   displayName    requires >= 2.1.143
#   relevance      requires >= 2.1.152
#   defaultEnabled requires >= 2.1.154
MIN_VERSIONED_KEYS='displayName|relevance|defaultEnabled'

scan() {
    # Key position only ("key":) — the same word inside a description
    # string must not flag.
    grep -nE "\"(${MIN_VERSIONED_KEYS})\"[[:space:]]*:" "$1"
}

if [ "$1" = "--self-test" ]; then
    TMP=$(mktemp)
    trap 'rm -f "$TMP"' EXIT
    printf '%s\n' '{ "plugins": [ { "name": "x", "displayName": "X" } ] }' > "$TMP"
    if ! scan "$TMP" > /dev/null; then
        echo "✗ self-test: fixture with displayName key was not flagged"
        exit 1
    fi
    printf '%s\n' '{ "plugins": [ { "name": "x", "description": "mentions displayName in prose" } ] }' > "$TMP"
    if scan "$TMP" > /dev/null; then
        echo "✗ self-test: displayName inside a description string was flagged"
        exit 1
    fi
    echo "✓ self-test passed"
    exit 0
fi

MANIFEST=.claude-plugin/marketplace.json
HITS=$(scan "$MANIFEST")
if [ -n "$HITS" ]; then
    echo "✗ $MANIFEST uses min-versioned plugin keys — older Claude Code"
    echo "  clients hard-fail '/plugin marketplace add' on ANY unrecognized"
    echo "  key (see issue #49), taking the whole marketplace down with it:"
    printf '%s\n' "$HITS" | sed 's/^/    /'
    exit 1
fi
echo "✓ $MANIFEST sticks to universally-recognized plugin keys"
exit 0
