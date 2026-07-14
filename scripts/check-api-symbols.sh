#!/bin/bash

# API tripwire — a skill must not teach an Apple symbol that does not exist, or
# quietly teach one Apple has deprecated.
#
# History: a harvest shipped `catch LanguageModelSession.GenerationError.cancelled`.
# There has never been a `.cancelled` case, in any SDK. It would not compile.
# It survived review because the surrounding prose was right and the docs site
# never contradicted it — nobody diffed the snippet against the actual SDK.
# check-freshness.sh could not catch it either: that script hunts recency claims
# next to stale VERSION numbers, and a wrong symbol carries no version at all.
#
# This closes that gap. Ground truth is scripts/api-symbols.txt, extracted from
# the SDK's .swiftinterface files by scripts/refresh-api-symbols.sh (macOS only).
# CI runs on ubuntu with no Xcode, so it reads the committed manifest instead.
#
# Two arms:
#   1. EXISTENCE   — `PolicedType.member` where `member` is not a real member.
#   2. DEPRECATION — a member the SDK marks deprecated, used on a line that does
#                    not say so. (Empty until an SDK that carries the annotation
#                    is installed; the FoundationModels iOS 26 SDK marks nothing.)
#
# Deliberate design choices — don`t "fix" these without a reason:
#   - Only types present in the manifest are policed. An unknown type is SKIPPED,
#     never flagged: absence of ground truth is not evidence of a bug. This is
#     why brand-new SDK symbols can`t produce false positives.
#   - A line containing ❌ is exempt. The repo`s convention is that ❌ marks a
#     counter-example, and counter-examples must be free to name the wrong
#     symbol — this file`s own motivating bug is now documented that way.
#   - `<!-- api-check: ignore -->` on the line is an explicit escape hatch.
#
# Usage:  ./scripts/check-api-symbols.sh              # scan skills/
#         ./scripts/check-api-symbols.sh --self-test  # run embedded fixtures
# Exit:   0 = clean, 1 = unknown or silently-deprecated symbol (or self-test fail)

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR" || exit 1

MANIFEST="scripts/api-symbols.txt"
VIOLATIONS=0

fail() {
    echo "  ✗ $1"
    VIOLATIONS=$((VIOLATIONS + 1))
}

if [ ! -f "$MANIFEST" ]; then
    echo "✗ $MANIFEST missing — run scripts/refresh-api-symbols.sh on a Mac with Xcode."
    exit 1
fi

# member_status <Type> <member>  ->  OK | DEPRECATED | UNKNOWN
member_status() {
    awk -F'\t' -v t="$1" -v m="$2" '
        $1 == t && $2 == m { print $3; found = 1; exit }
        END { if (!found) print "UNKNOWN" }
    ' "$MANIFEST"
}

# The set of policed types (skip comments/blank lines).
POLICED_TYPES=$(awk -F'\t' '!/^#/ && NF >= 3 { print $1 }' "$MANIFEST" | sort -u)

scan() {
    local target_dir="$1"
    for type in $POLICED_TYPES; do
        # Match `Type.member`, allowing a qualified prefix
        # (LanguageModelSession.GenerationError.cancelled).
        grep -rn "\b${type}\.[a-zA-Z_][a-zA-Z0-9_]*" "$target_dir" --include='*.md' 2>/dev/null \
        | while IFS= read -r hit; do
            file="${hit%%:*}"
            rest="${hit#*:}"
            line="${rest%%:*}"
            text="${rest#*:}"

            # Counter-examples and explicit opt-outs are allowed to name bad symbols.
            case "$text" in
                *❌*|*"api-check: ignore"*) continue ;;
            esac

            # A line may reference the type more than once.
            members=$(printf '%s\n' "$text" \
                | grep -oE "\b${type}\.[a-zA-Z_][a-zA-Z0-9_]*" \
                | sed "s/^${type}\.//" | sort -u)

            for m in $members; do
                # `TYPE` is the manifest`s own marker row, not a real member.
                [ "$m" = "TYPE" ] && continue
                status=$(member_status "$type" "$m")
                case "$status" in
                    OK) ;;
                    DEPRECATED)
                        case "$text" in
                            *[Dd]eprecat*|*⚠*|*[Mm]igrat*) ;;   # already flagged as such
                            *) echo "DEPRECATED|$file:$line|$type.$m" ;;
                        esac
                        ;;
                    UNKNOWN)
                        echo "UNKNOWN|$file:$line|$type.$m"
                        ;;
                esac
            done
        done
    done
}

# --- Self-test ----------------------------------------------------------------
if [ "${1:-}" = "--self-test" ]; then
    echo "== Self-test =="
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    # Fixture 1: the real bug. Must be caught.
    cat > "$tmp/bad.md" <<'FIXTURE'
} catch LanguageModelSession.GenerationError.cancelled {
FIXTURE

    # Fixture 2: real cases + a counter-example naming the bad one. Must be clean.
    cat > "$tmp/good.md" <<'FIXTURE'
} catch LanguageModelSession.GenerationError.guardrailViolation {
❌ Never write `catch GenerationError.cancelled` — that case does not exist.
A `GenerationError.rateLimited` is a real case. <!-- api-check: ignore -->
FIXTURE

    pass=0
    got_bad=$(scan "$tmp/bad.md" | grep -c 'UNKNOWN|.*GenerationError.cancelled')
    if [ "$got_bad" -eq 1 ]; then echo "  ✓ catches the .cancelled bug"; else echo "  ✗ MISSED the .cancelled bug"; pass=1; fi

    got_good=$(scan "$tmp/good.md" | grep -c .)
    if [ "$got_good" -eq 0 ]; then echo "  ✓ real cases + ❌ counter-examples stay clean"; else echo "  ✗ false positive on valid content:"; scan "$tmp/good.md" | sed 's/^/      /'; pass=1; fi

    [ "$pass" -eq 0 ] && { echo "✓ Self-test passed"; exit 0; } || { echo "✗ Self-test FAILED"; exit 1; }
fi

# --- Scan ---------------------------------------------------------------------
echo "== API symbols (ground truth: $(grep -c $'\t' "$MANIFEST") rows from $(grep '^# SDK:' "$MANIFEST" | cut -d: -f2- | xargs)) =="
echo "   policing: $(printf '%s ' $POLICED_TYPES)"
echo ""

results=$(scan "skills")

while IFS='|' read -r kind loc symbol; do
    [ -z "$kind" ] && continue
    case "$kind" in
        UNKNOWN)
            fail "$loc: \`$symbol\` is not a member of \`${symbol%%.*}\` in the SDK — typo, renamed, or invented?"
            ;;
        DEPRECATED)
            fail "$loc: \`$symbol\` is DEPRECATED — say so on the line, or teach the replacement"
            ;;
    esac
done <<< "$results"

echo ""
if [ "$VIOLATIONS" -eq 0 ]; then
    echo "✓ Every policed API symbol exists in the SDK"
    exit 0
fi
echo "✗ $VIOLATIONS API symbol problem(s)"
echo "  Verify against the SDK, not the docs:"
echo "    find \$(xcode-select -p)/Platforms -name '*.swiftinterface' -path '*<Framework>*'"
exit 1
