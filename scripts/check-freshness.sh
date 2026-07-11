#!/bin/bash

# Freshness tripwire — recency claims must not cite stale OS versions.
# History: a month after WWDC26 the library still said "Latest StoreKit
# Updates (iOS 18.4+)" — two OS generations stale under the word "Latest".
# A knowledge library rots annually on Apple's cadence; this makes the
# worst class of rot (claiming recency for an old version) a CI failure.
#
# Rule: a line FLAGS iff it contains a recency keyword AND an OS/Xcode
# version whose major is <= CURRENT-2 (Swift: <= CURRENT_SWIFT-1) on the
# SAME line. One-generation grace because until September GA the previous
# OS is still the shipping OS — "Latest (iOS 26)" stays true during the
# iOS 27 beta window, and the annual refresh happens inside the grace
# window instead of under a red CI.
#
# Deliberate design choices (don't "fix" these without a reason):
#   - `current`/`target` are NOT recency keywords (unlike skill-auditor
#     M-02): too noisy for CI — "current user", Transaction.currentEntitlements.
#     The auditor's ±2-line M-02 sweep remains the broader, human-reviewed net;
#     this script owns only the deterministic same-line subset.
#   - Version tokens are case-sensitive and require digits: GitHub runner
#     labels (`macos-15`) and placeholders (`iOS [X]`, `iOS [Version]`)
#     can never match.
#   - Plain availability gating never flags: "(iOS 18.4+)" with no recency
#     word on the line is a correct historical fact, not a freshness claim.
#
# Current-generation constants live in scripts/versions.env (bump once per
# WWDC). This script also cross-checks that skill-auditor's known-current
# constants were bumped along with the manifest.
#
# Usage:  ./scripts/check-freshness.sh              # scan the repo
#         ./scripts/check-freshness.sh --self-test  # run embedded fixtures
# Exit:   0 = clean, 1 = stale recency claim (or self-test failure)

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR" || exit 1

# shellcheck source=versions.env
. scripts/versions.env

VIOLATIONS=0
fail() {
    echo "  ✗ $1"
    VIOLATIONS=$((VIOLATIONS + 1))
}

# Recency keywords, case-insensitive, whole-word (-w) matched.
RECENCY_CI='latest|newest|now supports|now available|brand[- ]new|new in|as of'
# Heading style "New iOS 18.4+ SubscriptionOfferView" — case-sensitive so
# bare lowercase "new" never qualifies on its own. Leading boundary is
# explicit (not -w: the match ends mid-number, so -w would reject it).
RECENCY_CS='(^|[^A-Za-z0-9_])New (iOS|iPadOS|macOS|watchOS|tvOS|visionOS|Xcode|Swift) [0-9]'
# Version tokens: case-sensitive, digits required.
VERSION_TOKEN='(iOS|iPadOS|macOS|watchOS|tvOS|visionOS|Xcode) [0-9]+|Swift [0-9]+'

OS_LIMIT=$((CURRENT_OS_GEN - 2))
XCODE_LIMIT=$((CURRENT_XCODE - 2))
SWIFT_LIMIT=$((CURRENT_SWIFT_MAJOR - 1))

# Check one recency-candidate line for a stale version token.
check_line() {
    local file="$1" lineno="$2" line="$3" tok name major limit
    while IFS= read -r tok; do
        [ -n "$tok" ] || continue
        name="${tok% *}"
        major="${tok##* }"
        case "$name" in
            Xcode) limit="$XCODE_LIMIT" ;;
            Swift) limit="$SWIFT_LIMIT" ;;
            *)     limit="$OS_LIMIT" ;;
        esac
        if [ "$major" -le "$limit" ]; then
            fail "$file:$lineno stale '$tok' under recency language: $(printf '%s' "$line" | sed 's/^[[:space:]]*//' | cut -c1-90)"
            return
        fi
    done < <(printf '%s\n' "$line" | grep -oE "$VERSION_TOKEN")
}

# Scan a file: candidate lines = union of both recency prefilters.
scan_file() {
    local file="$1" lineno line
    while IFS=: read -r lineno line; do
        check_line "$file" "$lineno" "$line"
    done < <(
        { grep -niwE "$RECENCY_CI" "$file"
          grep -nE "$RECENCY_CS" "$file"
        } 2>/dev/null | sort -t: -k1,1n -u
    )
}

# --- Self-test: embedded fixtures, no files committed -------------------------
self_test() {
    local tmp
    tmp="$(mktemp -d)" || exit 1
    trap 'rm -rf "$tmp"' EXIT

    cat > "$tmp/must-flag.md" <<'EOF'
**Latest StoreKit Updates (iOS 18.4+):**
**New iOS 18.4+ SubscriptionOfferView:**
cannot be tested in Simulator (as of Xcode 15)
Latest Swift 5.9 features
EOF
    cat > "$tmp/must-pass.md" <<'EOF'
Rich text (iOS 26+)
**Latest Tested**: iOS [X]
runs-on: macos-15  # CI runner
what's new in macOS Tahoe or targets macOS 26
Transaction.currentEntitlements (iOS 18.4+)
EOF

    VIOLATIONS=0
    scan_file "$tmp/must-flag.md"
    if [ "$VIOLATIONS" -ne 4 ]; then
        echo "✗ self-test: expected 4 findings in must-flag fixtures, got $VIOLATIONS"
        exit 1
    fi
    VIOLATIONS=0
    scan_file "$tmp/must-pass.md" > /dev/null
    if [ "$VIOLATIONS" -ne 0 ]; then
        echo "✗ self-test: expected 0 findings in must-pass fixtures, got $VIOLATIONS"
        exit 1
    fi
    echo "✓ self-test passed (4 fixtures flagged, 5 fixtures clean)"
    exit 0
}

[ "${1:-}" = "--self-test" ] && self_test

# --- Main scan -----------------------------------------------------------------
echo "== Freshness scan: current gen OS $CURRENT_OS_GEN / Xcode $CURRENT_XCODE / Swift $CURRENT_SWIFT_MAJOR.x — stale = OS/Xcode <= $OS_LIMIT, Swift <= $SWIFT_LIMIT (with recency language on the same line) =="

# Sole exclusion: the auditor documents the drift heuristic itself and
# deliberately contains stale examples ("latest iOS 17", stage-1 ranges).
AUDITOR="skills/shared/skill-auditor/SKILL.md"

while IFS= read -r f; do
    [ "$f" = "$AUDITOR" ] && continue
    scan_file "$f"
done < <(
    { echo README.md
      ls docs/*.md 2>/dev/null
      find skills -name '*.md'
    }
)

echo ""
echo "== skill-auditor constants cross-check =="
if grep -q "iOS ${CURRENT_OS_GEN}" "$AUDITOR"; then
    echo "  ✓ auditor known-current constants mention iOS ${CURRENT_OS_GEN}"
else
    fail "skill-auditor known-current constants lag scripts/versions.env (no 'iOS ${CURRENT_OS_GEN}') — update the M-02 constants and Maintenance section in $AUDITOR"
fi

echo ""
if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✓ No stale recency claims"
    exit 0
else
    echo "✗ $VIOLATIONS stale recency claim(s) — update the content, or drop the recency word if the version gate is intentional"
    exit 1
fi
