#!/bin/bash
# Decay tripwire — skills past their `review_by:` frontmatter date.
#
# Complements check-freshness.sh: that script catches *provable* rot
# (recency claims naming stale OS versions, same line, deterministic);
# review_by is the scheduled human re-verification date every skill carries
# (default: ~2 weeks after the next WWDC). This script lists what's overdue.
#
# NOT wired into validate.yml on purpose: the week after WWDC most of the
# library goes overdue at once by design — that's a work queue, not a broken
# PR. The stale-skills workflow turns this into rollup issues weekly.
#
# Usage:
#   ./scripts/check-review-by.sh              # human summary; exit 1 if any overdue
#   ./scripts/check-review-by.sh --list       # TSV: category<TAB>path<TAB>review_by (exit 0)
#   ./scripts/check-review-by.sh --self-test  # verify detection logic on fixtures
#
# SKILLS_DIR override supported (self-test uses it).

set -u
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="${SKILLS_DIR:-$REPO_DIR/skills}"
TODAY=$(date +%F)

overdue() {
    # Emits: category<TAB>path<TAB>review_by for every overdue SKILL.md.
    # YYYY-MM-DD compares correctly as a string — no date parsing needed.
    find "$SKILLS" -name SKILL.md ! -path "*/_shared/*" | sort | while IFS= read -r f; do
        rb=$(awk 'NR>1 && /^---$/{exit} /^review_by:/{print $2}' "$f")
        [ -n "$rb" ] || continue
        if [[ "$rb" < "$TODAY" ]]; then
            rel=${f#"$SKILLS"/}
            printf '%s\t%s\t%s\n' "${rel%%/*}" "$rel" "$rb"
        fi
    done
}

if [ "${1:-}" = "--self-test" ]; then
    T=$(mktemp -d)
    mkdir -p "$T/cat-a/expired" "$T/cat-a/fresh" "$T/cat-b/undated"
    printf -- '---\nname: expired\nreview_by: 2000-01-01\n---\n' > "$T/cat-a/expired/SKILL.md"
    printf -- '---\nname: fresh\nreview_by: 2999-01-01\n---\n'   > "$T/cat-a/fresh/SKILL.md"
    printf -- '---\nname: undated\n---\n'                        > "$T/cat-b/undated/SKILL.md"
    OUT=$(SKILLS_DIR="$T" "$0" --list)
    rm -rf "$T"
    echo "$OUT" | grep -q "cat-a	cat-a/expired/SKILL.md	2000-01-01" || { echo "✗ self-test: expired not detected"; exit 1; }
    [ "$(echo "$OUT" | grep -c .)" -eq 1 ] || { echo "✗ self-test: false positive (fresh/undated flagged)"; exit 1; }
    echo "✓ check-review-by self-test passed"
    exit 0
fi

if [ "${1:-}" = "--list" ]; then
    overdue
    exit 0
fi

LIST=$(overdue)
if [ -z "$LIST" ]; then
    echo "✓ No skills past their review_by date"
    exit 0
fi
N=$(printf '%s\n' "$LIST" | grep -c .)
echo "✗ $N skill(s) past review_by (today: $TODAY):"
printf '%s\n' "$LIST" | awk -F'\t' '{printf "  %s (review_by %s)\n", $2, $3}'
exit 1
