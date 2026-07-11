#!/bin/bash

# Swift template syntax check — every standalone .swift file must parse.
# History: deep-linking/templates/AppShortcuts.swift shipped a `struct`
# conforming to AppEnum with `case` members — a parse error, live in the
# repo for months. Generators emit these files into users' projects as
# "production-ready"; the least they must do is parse.
#
# The bar is PARSE-ONLY (`swiftc -parse`): full type-checking needs Apple
# SDKs that don't exist on the Linux CI toolchain, and templates import
# SwiftUI/StoreKit/etc. Parse still catches structural breakage (unbalanced
# braces, struct-with-cases, truncated files).
#
# Fenced ```swift blocks in .md files are deliberately OUT of scope:
# ~2,900 blocks across ~260 files, a large share intentionally
# non-standalone (single modifiers, bare enum cases, before/after diffs).
# Parse-checking them mass-fails or needs fragile wrapper heuristics, and
# a noisy check trains contributors to ignore CI.
# TODO(opt-in): parse only blocks whose fence info string is ```swift check
#
# CI runs this in the official `swift:` container (see validate.yml — the
# image tag pins the toolchain; adopting newer-Swift-only syntax in a
# template requires bumping that tag). Locally it uses Xcode's swiftc.
#
# Usage:  ./scripts/check-swift-templates.sh
# Exit:   0 = all parse, 1 = parse failure(s)

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR" || exit 1

SWIFTC="$(command -v swiftc || xcrun -f swiftc 2>/dev/null)"
if [ -z "$SWIFTC" ]; then
    echo "✗ no swiftc found (install Xcode command line tools, or run in the swift container)"
    exit 1
fi

VIOLATIONS=0
CHECKED=0
fail() {
    echo "  ✗ $1"
    VIOLATIONS=$((VIOLATIONS + 1))
}

while IFS= read -r f; do
    CHECKED=$((CHECKED + 1))
    if ! OUTPUT=$("$SWIFTC" -parse "$f" 2>&1); then
        fail "$f does not parse:"
        printf '%s\n' "$OUTPUT" | head -8 | sed 's/^/      /'
    fi
done < <(find skills -name '*.swift' | sort)

echo ""
if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✓ All $CHECKED .swift template files parse ($("$SWIFTC" --version | head -1))"
    exit 0
else
    echo "✗ $VIOLATIONS of $CHECKED .swift template file(s) failed to parse"
    exit 1
fi
