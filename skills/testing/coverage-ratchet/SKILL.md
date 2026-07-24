---
name: coverage-ratchet
description: Gate test coverage with a ratchet — a committed baseline that coverage may never drop below and only ever rises. Ships a coverage-gate script (xccov-based) plus an advisory CRAP report (complexity × uncovered). Use when agent-written code needs a deterministic "tests were actually written" check.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
last_verified: 2026-07-24
review_by: 2027-07-01
---

# Coverage Ratchet

A build/test gate proves the tests that exist pass. It says nothing about whether tests were *written* — a phase with no test task ships green on build success alone. The coverage ratchet closes that hole deterministically: line coverage is measured on every verify, compared against a committed baseline, and may never drop. It only rises.

## Why a Ratchet, Not a Target

An absolute threshold ("80%") fails one of two ways on a real codebase: it fails day one (so it gets disabled), or it gets set below current reality (so it gates nothing). A ratchet starts *from wherever the project actually is* and only tightens. Nobody argues with "don't get worse."

## When This Skill Activates

Use this skill when:
- A project has a test target but coverage has never been measured
- Agent-written features keep arriving with build-passing, test-free code
- Setting up the deterministic gauntlet (with `testing/fitness-functions/` and `swift/code-size/`)

## Setup

1. Copy `templates/coverage-gate.sh` into the project (e.g. `Scripts/coverage-gate.sh`), make it executable, and fill in the config block (scheme, destination, app target name).
2. Bootstrap the baseline:

```bash
Scripts/coverage-gate.sh --init     # runs tests with coverage, writes .coverage-baseline
```

3. Commit both the script and `.coverage-baseline`.

`.coverage-baseline` holds a single decimal fraction (e.g. `0.6231`) — the app target's line coverage. Trailing whitespace ignored; nothing else in the file.

## The Gate

```bash
Scripts/coverage-gate.sh            # exit 0 = pass, exit 1 = coverage dropped
```

- Runs the test suite with coverage enabled, extracts the app target's line coverage from the `xccov` JSON report.
- **Fails** if `current < baseline − 0.0025` (the epsilon absorbs measurement jitter from unchanged code).
- **Suggests a ratchet-up** when `current > baseline + 0.01`: update `.coverage-baseline` to the new number in the same commit as the tests that earned it. That's the ratchet clicking forward.
- Fails **loudly** on an unexpected report shape or a missing target — a broken measurement must never read as a pass.

Ratchet-up etiquette: raising the baseline is routine and encouraged; *lowering* it requires a written reason in the commit message (e.g. deleting a well-covered module) — treat it like widening a fitness-function allowlist.

## CRAP Report (Advisory)

`templates/crap-report.sh` combines per-function cyclomatic complexity (SwiftLint JSON output) with per-function coverage (the same xccov report) into the CRAP score — Change Risk Anti-Patterns:

```
CRAP(f) = complexity(f)² × (1 − coverage(f))³ + complexity(f)
```

A complex *and* untested function scores explosively; simple-and-tested stays near its complexity. The report prints the top 20 — the exact functions where a test is worth the most. **Advisory only, never a gate**: the name-join between the two tools is heuristic.

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Absolute threshold on existing code | Fails day one or gates nothing | Ratchet from measured reality |
| Gating total project coverage | Test-target/generated code pollutes the number | Gate the app target's own lineCoverage |
| Silent pass on tool failure | Broken measurement reads as green | Script fails loudly on unexpected JSON |
| Chasing the number with assertion-free tests | Coverage without verification | Pair with mutation spot-checks (`testing/mutation-testing/`) |
| Never ratcheting up | Baseline fossilizes at day-one level | Raise it in the same commit as new tests |

## References

- `testing/mutation-testing/` — do the covering tests actually assert anything (advisory)
- `swift/code-size/` — the complexity half; small functions are coverable functions
- `testing/fitness-functions/` — architecture invariants as tests
- `generators/ci-cd-setup/` — CI wiring for the gate
