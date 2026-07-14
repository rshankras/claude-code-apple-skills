#!/bin/bash

# Count-sync validator — documented skill counts must match the tree.
# History: the README has shipped four different totals (143/145/148/…) as
# skills landed without doc bumps. This makes that structurally impossible.
#
# Counting rule (same as the README's "What's Included" table):
#   - a skill = skills/<category>/<skill>/SKILL.md
#   - PLUS single-skill categories whose category-level SKILL.md IS the skill
#     (listed in CATEGORY_LEVEL_SKILLS below — extend it consciously)
#   - other category-level SKILL.md files are indexes and don't count
#   - _shared/ holds internal helpers, not skills or a category
#
# Usage:  ./scripts/check-counts.sh
# Exit:   0 = in sync, 1 = drift found

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR" || exit 1

VIOLATIONS=0
fail() {
    echo "  ✗ $1"
    VIOLATIONS=$((VIOLATIONS + 1))
}

# Categories whose category-level SKILL.md is itself the (only) skill.
# Adding a new one? Add it here AND to the README table.
CATEGORY_LEVEL_SKILLS="core-ml monetization watchos release-review security"

# --- Compute ground truth ---------------------------------------------------
SKILL_DIRS=$(find skills -mindepth 3 -maxdepth 3 -name "SKILL.md" | wc -l | tr -d ' ')
CAT_SKILLS=0
for c in $CATEGORY_LEVEL_SKILLS; do
    if [ -f "skills/$c/SKILL.md" ]; then
        CAT_SKILLS=$((CAT_SKILLS + 1))
    else
        fail "skills/$c/SKILL.md missing but listed in CATEGORY_LEVEL_SKILLS"
    fi
done
TOTAL=$((SKILL_DIRS + CAT_SKILLS))
CATS=$(find skills -mindepth 1 -maxdepth 1 -type d ! -name "_shared" | wc -l | tr -d ' ')

echo "== Ground truth: $TOTAL skills ($SKILL_DIRS skill dirs + $CAT_SKILLS category-level) across $CATS categories =="

# --- 1. Totals everywhere they appear ----------------------------------------
echo ""
echo "== Totals in README + docs =="
grep -qF "| $TOTAL skills" README.md \
    || fail "README stack table: expected '$TOTAL skills'"
grep -qF "Total: $TOTAL skills across $CATS categories" README.md \
    || fail "README: expected 'Total: $TOTAL skills across $CATS categories'"
for f in docs/USAGE.md docs/QUICK_START.md; do
    [ -f "$f" ] || continue
    grep -qF "$TOTAL skills across $CATS categories" "$f" \
        || fail "$f: expected '$TOTAL skills across $CATS categories'"
done
grep -qF "**$TOTAL across $CATS categories**" docs/ROADMAP.md \
    || fail "docs/ROADMAP.md: expected '**$TOTAL across $CATS categories**'"
# The plugin manifests hardcode the total in their descriptions too.
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
    grep -qF "$TOTAL " "$f" \
        || fail "$f: description should mention '$TOTAL' skills"
done

# --- 2. Per-category counts in the README table ------------------------------
echo ""
echo "== Per-category counts in README 'What's Included' table =="
# "README label|directory" pairs — every row in the table.
PAIRS="Generators|generators
Product|product
iOS|ios
Testing|testing
macOS|macos
App Store|app-store
SwiftUI|swiftui
Growth|growth
Swift|swift
Apple Intelligence|apple-intelligence
Design|design
Performance|performance
Security|security
Core ML|core-ml
Legal|legal
Monetization|monetization
watchOS|watchos
SwiftData|swiftdata
MapKit|mapkit
Foundation|foundation
visionOS|visionos
Release Review|release-review
Shared|shared"

CHECKED=0
SUM=0
while IFS='|' read -r label dir; do
    n=$(find "skills/$dir" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
    case " $CATEGORY_LEVEL_SKILLS " in
        *" $dir "*) n=$((n + 1)) ;;
    esac
    grep -qF "| **$label** | $n |" README.md \
        || fail "README table: expected '| **$label** | $n |' (tree has $n for skills/$dir)"
    CHECKED=$((CHECKED + 1))
    SUM=$((SUM + n))
done <<EOF
$PAIRS
EOF

[ "$SUM" -eq "$TOTAL" ] || fail "table rows sum to $SUM but total is $TOTAL — a category is missing from this script's PAIRS list"
echo "  checked $CHECKED categories (rows sum to $SUM)"

# --- 3. Every category dir appears in the table (catches new categories) -----
for d in $(find skills -mindepth 1 -maxdepth 1 -type d ! -name "_shared" -exec basename {} \;); do
    printf '%s\n' "$PAIRS" | grep -q "|$d\$" \
        || fail "skills/$d exists but has no row mapping in this script — add it to PAIRS and the README table"
done

# --- 4. Listings match the tree (README tables, category indexes, ROADMAP) ----
# Counts alone let name lists rot (a skill lands, the table row count is bumped,
# but the skill is never *named*). Three surfaces claim per-skill name coverage:
echo ""
echo "== Listings match the tree =="
LISTED=0

# 4a. README per-skill tables — categories that have one must name every skill.
#     Give a new category a README table? Add it here.
README_TABLE_CATS="generators growth legal testing monetization swiftui performance app-store security design visionos"
for cat in $README_TABLE_CATS; do
    for f in $(find "skills/$cat" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null); do
        s=$(basename "$(dirname "$f")")
        grep -q "$s" README.md \
            || fail "README: skills/$cat/$s is not named in its per-skill table"
        LISTED=$((LISTED + 1))
    done
done

# 4b. Category indexes — a SKILL.md with an '## Available Skills' section must
#     name every member skill.
for idx in skills/*/SKILL.md; do
    grep -q "## Available Skills" "$idx" || continue
    catdir=$(dirname "$idx")
    for f in $(find "$catdir" -mindepth 2 -maxdepth 2 -name "SKILL.md"); do
        s=$(basename "$(dirname "$f")")
        grep -q "$s" "$idx" \
            || fail "$idx: 'Available Skills' does not name $s"
        LISTED=$((LISTED + 1))
    done
done

# 4c. ROADMAP's 'Skills by Category' name lists claim full coverage — every
#     skill dir must be named somewhere in docs/ROADMAP.md.
for f in $(find skills -mindepth 3 -maxdepth 3 -name "SKILL.md" ! -path "skills/_shared/*"); do
    s=$(basename "$(dirname "$f")")
    c=$(basename "$(dirname "$(dirname "$f")")")
    grep -q "$s" docs/ROADMAP.md \
        || fail "docs/ROADMAP.md: $c/$s is not named in any category row"
    LISTED=$((LISTED + 1))
done
echo "  checked $LISTED listing entries"

# --- 5. Cross-repo: SwiftShip command count ----------------------------------
echo ""
echo "== Cross-repo counts (SwiftShip) =="
# History: marketplace.json advertised "49 /apple:* workflow commands" while the
# README said 52 — i.e. the copy users read *in the install prompt* was the one
# that rotted. The old check missed it twice over: it grepped only README.md,
# and its single grep -qF passed if ANY line matched, so a second stale README
# mention would also have slid through. It also ran only when a sibling
# SwiftShip checkout happened to exist — never true on CI — so in practice it
# was dead code.
#
# Two arms now, and the first one always runs:
#   a) internal consistency — every surface that states the count must state the
#      SAME count. Needs no checkout, so CI enforces it.
#   b) ground truth — when a SwiftShip checkout IS present (local dev, or CI if
#      a checkout step is ever added), that agreed count must equal the real
#      number of commands/*.md files.
#
# Surfaces state the count in two phrasings ("N /apple:* commands" in README,
# "N /apple:* workflow commands" in marketplace.json), so match the common
# "N /apple:*" prefix rather than either full phrase.
SWIFTSHIP="${SWIFTSHIP_DIR:-$REPO_DIR/../SwiftShip}"
SS_SURFACES="README.md .claude-plugin/marketplace.json"
# shellcheck disable=SC2086
SS_MENTIONS=$(grep -ohE '[0-9]+ /apple:\*' $SS_SURFACES)
SS_N=$(printf '%s\n' "$SS_MENTIONS" | grep -c '[0-9]')

# Vacuity guard: if a rewording drops the phrase, this check must fail loudly
# rather than quietly verify nothing. Today: README x2, marketplace.json x1.
if [ "$SS_N" -lt 3 ]; then
    fail "expected >=3 SwiftShip command-count mentions across $SS_SURFACES, found $SS_N — did the wording change? Update this check, don't delete it"
else
    SS_STATED=$(printf '%s\n' "$SS_MENTIONS" | grep -oE '^[0-9]+' | sort -u)
    if [ "$(printf '%s\n' "$SS_STATED" | wc -l | tr -d ' ')" -ne 1 ]; then
        fail "SwiftShip command count disagrees across surfaces ($(printf '%s' "$SS_STATED" | tr '\n' '/')) — README.md and .claude-plugin/marketplace.json must state the same number"
    else
        echo "  $SS_N mentions agree on $SS_STATED commands"
        if [ -d "$SWIFTSHIP/commands" ]; then
            CMDS=$(find "$SWIFTSHIP/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
            [ "$SS_STATED" -eq "$CMDS" ] \
                || fail "docs say $SS_STATED SwiftShip commands but the checkout at $SWIFTSHIP has $CMDS"
            echo "  ground truth: $SWIFTSHIP has $CMDS commands"
        else
            echo "  (no SwiftShip checkout at $SWIFTSHIP — internal consistency checked, ground truth skipped)"
        fi
    fi
fi

# --- Result -------------------------------------------------------------------
echo ""
if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✓ All counts in sync"
    exit 0
else
    echo "✗ $VIOLATIONS count violation(s) — update the docs (or this script, if the rule changed)"
    exit 1
fi
