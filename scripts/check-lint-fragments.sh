#!/bin/bash
# Lint-fragment validator — every skill `rules/swiftlint.yml` must:
#   (a) be a config SwiftLint accepts,
#   (b) fire each of its rules on its violation fixture,
#   (c) stay quiet (its rules only) on its clean fixture.
#
# Fixture convention: tools/lint-fixtures/<skill-path-with-dashes>/{violation,clean}/
# e.g. skills/ios/coding-best-practices/rules/swiftlint.yml
#   →  tools/lint-fixtures/ios-coding-best-practices/
#
# A rule that never fires on its own fixture is a broken promise; a rule that
# fires on the clean fixture cries wolf — both fail CI. Default-rule noise on
# fixtures is ignored: only the fragment's own rule ids are asserted.
#
# Requires swiftlint (CI runs the official container). Locally without the
# binary it skips with a notice — CI is the authority.

cd "$(dirname "$0")/.." || exit 1

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "⚠ swiftlint not installed — fragment fixtures not validated here (CI covers this)"
    exit 0
fi

fails=0
found=0
for frag in skills/*/rules/swiftlint.yml skills/*/*/rules/swiftlint.yml; do
    [ -f "$frag" ] || continue
    found=$((found+1))
    rel=${frag#skills/}; rel=${rel%/rules/swiftlint.yml}
    fixture="tools/lint-fixtures/${rel//\//-}"
    if [ ! -d "$fixture/violation" ] || [ ! -d "$fixture/clean" ]; then
        echo "  ✗ $frag: missing fixture dirs at $fixture/{violation,clean}"
        fails=$((fails+1)); continue
    fi

    # Rule ids = custom_rules keys (2-space indent) + opt_in_rules entries.
    ids=$( { awk '/^custom_rules:/{c=1;next} c && /^  [a-z_]+:/{gsub(/[: ]/,"");print} c && /^[^ #]/{c=0}' "$frag"
             awk '/^opt_in_rules:/{o=1;next} o && /^  - /{print $2} o && /^[^ #]/{o=0}' "$frag"; } | sort -u )
    if [ -z "$ids" ]; then
        echo "  ✗ $frag: no rule ids found (empty fragment?)"; fails=$((fails+1)); continue
    fi

    abs_frag="$PWD/$frag"
    v_out=$( (cd "$fixture/violation" && swiftlint lint --config "$abs_frag" --reporter csv --quiet) 2>/dev/null )
    c_out=$( (cd "$fixture/clean"     && swiftlint lint --config "$abs_frag" --reporter csv --quiet) 2>/dev/null )

    frag_fails=0
    for id in $ids; do
        printf '%s\n' "$v_out" | grep -q ",$id\$" \
            || { echo "  ✗ $frag: rule '$id' did not fire on $fixture/violation"; frag_fails=$((frag_fails+1)); }
        printf '%s\n' "$c_out" | grep -q ",$id\$" \
            && { echo "  ✗ $frag: rule '$id' fired on $fixture/clean (false positive)"; frag_fails=$((frag_fails+1)); }
    done
    fails=$((fails+frag_fails))
    [ "$frag_fails" -eq 0 ] && echo "  ✓ $frag ($(echo "$ids" | wc -l | tr -d ' ') rules verified)"
done

echo ""
if [ "$found" -eq 0 ]; then
    echo "✗ no rules/swiftlint.yml fragments found — glob broken?"
    exit 1
fi
if [ "$fails" -eq 0 ]; then
    echo "✓ All $found lint fragments verified against fixtures"
    exit 0
fi
echo "✗ $fails fragment problem(s)"
exit 1
