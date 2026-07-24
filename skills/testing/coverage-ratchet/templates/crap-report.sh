#!/bin/bash
# crap-report.sh — CRAP metric report (from skills/testing/coverage-ratchet)
#
#   CRAP(f) = complexity(f)² × (1 − coverage(f))³ + complexity(f)
#
# Combines per-function cyclomatic complexity (SwiftLint JSON reporter) with
# per-function line coverage (xccov JSON) and prints the top 20 — the
# functions where a new test buys the most risk reduction.
#
# ADVISORY ONLY — never wire this as a gate. The join between SwiftLint's
# violation locations and xccov's function names is heuristic (file + line
# proximity); treat the output as a worklist, not a verdict.
#
# Usage: ./crap-report.sh <path/to/coverage.xcresult>
#   (reuse the result bundle coverage-gate.sh produces, or any -resultBundlePath)

set -u

if [ $# -lt 1 ] || [ ! -e "$1" ]; then
    echo "usage: $0 <coverage.xcresult>"; exit 1
fi
RESULT_BUNDLE="$1"

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "✗ swiftlint not installed — complexity half unavailable"; exit 1
fi

COMPLEXITY_JSON="$(mktemp)"
COVERAGE_JSON="$(mktemp)"

# All cyclomatic_complexity findings, thresholds floored to 1 so every
# function above complexity 1 is reported for scoring purposes.
swiftlint lint --quiet --reporter json \
    --config /dev/stdin > "$COMPLEXITY_JSON" 2>/dev/null <<'YML'
only_rules: [cyclomatic_complexity]
cyclomatic_complexity:
  warning: 2
  error: 1000
YML

xcrun xccov view --report --json "$RESULT_BUNDLE" > "$COVERAGE_JSON" 2>/dev/null || {
    echo "✗ xccov could not read $RESULT_BUNDLE"; exit 1
}

python3 - "$COMPLEXITY_JSON" "$COVERAGE_JSON" <<'PY'
import json, re, sys, os

with open(sys.argv[1]) as f:
    lint = json.load(f)
with open(sys.argv[2]) as f:
    cov = json.load(f)

# file path -> [(line, function name, lineCoverage)]
functions_by_file = {}
for target in cov.get("targets", []):
    for fl in target.get("files", []):
        entries = [(fn.get("lineNumber", 0), fn.get("name", "?"), fn.get("lineCoverage", 0.0))
                   for fn in fl.get("functions", [])]
        functions_by_file[os.path.basename(fl.get("path", ""))] = sorted(entries)

rows = []
for v in lint:
    m = re.search(r"complexity of (\d+)", v.get("reason", ""))
    if not m:
        continue
    complexity = int(m.group(1))
    base = os.path.basename(v.get("file", ""))
    line = v.get("line", 0)
    # nearest function at or before the violation line (heuristic join)
    name, coverage = "?", 0.0
    for fn_line, fn_name, fn_cov in functions_by_file.get(base, []):
        if fn_line <= line:
            name, coverage = fn_name, fn_cov
        else:
            break
    crap = complexity ** 2 * (1 - coverage) ** 3 + complexity
    rows.append((crap, complexity, coverage, base, line, name))

rows.sort(reverse=True)
print(f"{'CRAP':>8}  {'CC':>3}  {'cov':>5}  location")
for crap, cc, coverage, base, line, name in rows[:20]:
    print(f"{crap:8.1f}  {cc:3d}  {coverage:5.0%}  {base}:{line}  {name}")
if not rows:
    print("no functions above the complexity floor — nothing to report")
PY
