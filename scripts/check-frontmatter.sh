#!/bin/bash
# Every SKILL.md must open with --- and declare name: and description: in its
# frontmatter. Plugin installs surface skills by frontmatter name — a missing
# name falls back to an unstable install-directory string, so this is a
# distribution contract, not a style check. Kept separate from check-counts.sh
# (counts) on purpose.
cd "$(dirname "$0")/.." || exit 1

fails=0
while IFS= read -r f; do
    if ! head -1 "$f" | grep -q '^---$'; then
        echo "  ✗ $f: does not open with frontmatter (---)"
        fails=$((fails+1))
        continue
    fi
    fm=$(awk 'NR>1 && /^---$/{exit} NR>1{print}' "$f")
    printf '%s\n' "$fm" | grep -q '^name:'        || { echo "  ✗ $f: missing name:"; fails=$((fails+1)); }
    printf '%s\n' "$fm" | grep -q '^description:' || { echo "  ✗ $f: missing description:"; fails=$((fails+1)); }
    # Freshness dates (added 2026-07): both required, strict YYYY-MM-DD.
    # Overdue-ness is NOT checked here (that's check-review-by.sh + the weekly
    # stale-skills workflow) — presence and format are the PR-blocking contract.
    for key in last_verified review_by; do
        printf '%s\n' "$fm" | grep -Eq "^$key: [0-9]{4}-[0-9]{2}-[0-9]{2}$" \
            || { echo "  ✗ $f: missing or malformed $key: (want YYYY-MM-DD)"; fails=$((fails+1)); }
    done
done < <(find skills -name SKILL.md)

if [ "$fails" -eq 0 ]; then
    echo "✓ All SKILL.md frontmatter valid (name, description, last_verified, review_by)"
    exit 0
fi
echo "✗ $fails frontmatter problem(s)"
exit 1
