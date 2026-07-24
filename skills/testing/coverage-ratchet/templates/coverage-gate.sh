#!/bin/bash
# coverage-gate.sh — coverage ratchet (from skills/testing/coverage-ratchet)
#
#   ./coverage-gate.sh          run tests + gate against .coverage-baseline
#   ./coverage-gate.sh --init   run tests + write the initial baseline
#
# The gate: the app target's line coverage may never drop below the committed
# baseline (minus a small jitter epsilon). Raising the baseline is routine —
# do it in the same commit as the tests that earned it. Lowering it requires
# a written reason in the commit message.
#
# Fails LOUDLY on unexpected xccov output or a missing target — a broken
# measurement must never read as a pass.

set -u  # deliberate: no `set -e`; every failure path exits explicitly with a message

# ── Config — ADAPT to the project ────────────────────────────────────────────
SCHEME="YourApp"
DESTINATION="platform=iOS Simulator,name=iPhone 16"
TARGET_NAME="YourApp.app"          # target name as it appears in the xccov report
BASELINE_FILE=".coverage-baseline"
EPSILON="0.0025"                   # tolerated jitter below baseline
RATCHET_HINT="0.01"                # suggest raising baseline when above by this
# ─────────────────────────────────────────────────────────────────────────────

cd "$(dirname "$0")/.." || exit 1

RESULT_BUNDLE="$(mktemp -d)/coverage.xcresult"

echo "▸ Running tests with coverage (scheme: $SCHEME)…"
if ! xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE" \
    -quiet; then
    echo "✗ test run failed — coverage not evaluated (fix the tests first)"
    exit 1
fi

REPORT_JSON="$(mktemp)"
if ! xcrun xccov view --report --json "$RESULT_BUNDLE" > "$REPORT_JSON" 2>/dev/null; then
    echo "✗ xccov could not read the result bundle at $RESULT_BUNDLE"
    exit 1
fi

CURRENT=$(python3 - "$REPORT_JSON" "$TARGET_NAME" <<'PY'
import json, sys
path, wanted = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        report = json.load(f)
    targets = report["targets"]
    matches = [t for t in targets if t["name"] == wanted]
    if not matches:
        names = ", ".join(t.get("name", "?") for t in targets)
        sys.stderr.write(f"target '{wanted}' not in report (targets: {names})\n")
        sys.exit(2)
    print(f"{matches[0]['lineCoverage']:.4f}")
except (KeyError, json.JSONDecodeError) as e:
    sys.stderr.write(f"unexpected xccov report shape: {e} (raw report: {path})\n")
    sys.exit(2)
PY
)
if [ -z "${CURRENT:-}" ]; then
    echo "✗ could not extract line coverage for '$TARGET_NAME' — refusing to pass silently"
    exit 1
fi

echo "▸ $TARGET_NAME line coverage: $CURRENT"

if [ "${1:-}" = "--init" ]; then
    printf '%s\n' "$CURRENT" > "$BASELINE_FILE"
    echo "✓ baseline initialized: $BASELINE_FILE = $CURRENT (commit this file)"
    exit 0
fi

if [ ! -f "$BASELINE_FILE" ]; then
    echo "✗ no $BASELINE_FILE — run '$0 --init' once and commit the result"
    exit 1
fi
BASELINE=$(tr -d '[:space:]' < "$BASELINE_FILE")

python3 - "$CURRENT" "$BASELINE" "$EPSILON" "$RATCHET_HINT" <<'PY'
import sys
current, baseline, epsilon, hint = map(float, sys.argv[1:5])
if current < baseline - epsilon:
    print(f"✗ COVERAGE DROPPED: {current:.4f} < baseline {baseline:.4f} (epsilon {epsilon})")
    print("  New code shipped without tests. Add tests, or lower the baseline")
    print("  with a written reason in the commit message.")
    sys.exit(1)
if current > baseline + hint:
    print(f"✓ coverage {current:.4f} ≥ baseline {baseline:.4f}")
    print(f"  ↑ ratchet opportunity: raise the baseline to {current:.4f} in this commit.")
else:
    print(f"✓ coverage {current:.4f} ≥ baseline {baseline:.4f}")
sys.exit(0)
PY
exit $?
