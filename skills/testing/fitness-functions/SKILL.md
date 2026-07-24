---
name: fitness-functions
description: Write architecture fitness functions — deterministic tests that enforce a project's hard rules (module boundaries, offline guarantees, content contracts) from inside its own test target. Use when a constraint lives only in prose (CLAUDE.md, code review) and should become un-arguable.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
last_verified: 2026-07-24
review_by: 2027-07-01
---

# Architecture Fitness Functions

A fitness function is an ordinary test that enforces an architectural rule instead of a behavior. It lives in the app's own test target, runs under every existing test gate forever, and turns "the agent said it's fine" into an exit code. This is the gauntlet's answer for invariants no unit test of behavior can see: a file quietly importing a framework it must not touch, a registry drifting from its documented size, user-facing copy breaking its format contract.

## When This Skill Activates

Use this skill when:
- A project hard rule exists only in prose — CLAUDE.md constraints, file-header comments, review checklists ("deck games must run fully offline", "only the sync layer may import CloudKit")
- A code review keeps re-checking the same structural rule by hand
- An `/apple:review` structural finding is being graduated into permanent enforcement
- A count, boundary, or content format was broken silently once already

## Why a Test, Not a Lint Rule

A per-line regex (SwiftLint `custom_rules`) can flag a *line*. A fitness function can assert a *set*: "the files importing MusicKit are exactly these four", "the mode registry has exactly 21 entries", "every case's copy fits the format". Sets, counts, and cross-file facts need code, and putting that code in the test target means no new tooling, no CI wiring — it rides the `test` gate that already exists.

## The Three Patterns

### Pattern 1: Import-Boundary Allowlist Scan

Enforces "only these files may import X." The test walks the shipped source tree and compares the *actual* importer set against an allowlist — so a fifth importer fails a test, not a code review.

Key rules (learned in production):
- **Resolve the source root from `#filePath`**, never a hardcoded path — the test stays correct wherever the repo is checked out.
- **Match exact trimmed lines** (`line == "import X"`), not `contains` — comments documenting the contract itself must not count as hits.
- **Compare full sets, not counts** — the failure message then names the drifted file.
- **Exclude non-shipping directories deliberately** (DEBUG-only spikes, generated code) and say why in a comment: the guarantee is about what ships.
- **The allowlist is a fence, not a headcount.** Widening it is a legitimate, *documented* decision: when a new file genuinely belongs inside the boundary, the test failing is the system working — record why in the allowlist comment, then add it.
- **Add a companion API-surface scan** for bypass routes the import check can't see. An import-only check misses a file calling the underlying API directly (every file already imports Foundation, which is enough to reach `URLSession` without importing the fenced framework). Scan for the raw API strings (`URLSession(`, `URLSession.shared`) outside the boundary too.

Template: `templates/ImportBoundaryTests.swift`

### Pattern 2: Runtime Sentinel

Enforces "this code path never *attempts* X" — stronger than "happens to succeed without X." The canonical case is an offline guarantee: register a `URLProtocol` subclass that intercepts, counts, and fails every network request, drive the real production path, and assert the counter stayed at zero.

Key rules:
- Register the sentinel per-test and unregister in `defer`.
- The sentinel **fails** requests loudly (never lets them reach the network) — a regression fails in CI instead of silently succeeding against a live server.
- Assert `interceptedRequestCount == 0`: the contract is *zero attempts*, not zero successes.
- Drive the real path (real service, real composition), with only storage in-memory.

Template: `templates/NetworkSentinelTests.swift`

### Pattern 3: Contract Pins

Pins facts that must change *deliberately*, never by drift.

**Count pins** — registry and configuration sizes:

```swift
// Phase 3.5 added 3 modes — 9 modes, 5 streaming.
// Phase 3.8 added the four reunion music games — 15 modes, 9 streaming.
// Phase 3.10 added the DJ-host quartet — 18 modes, 10 streaming.
#expect(PartyOccasion.bigParty.modes.count == 18)
#expect(PartyOccasion.bigParty.modes.filter(\.usesDJEngine).count == 10)
```

The comment trail is mandatory: each pinned number carries its history, so updating the pin is a reviewed decision with a written reason, not a chore silenced with an edit.

**Copy-contract pins** — structural rules on user-facing content, iterated over `CaseIterable` so new cases are covered automatically:

```swift
@Test func everyModeHasExactlyThreeBeats() {
    for mode in GameMode.allCases {
        #expect(mode.howItPlaysBeats.count == 3, "\(mode.rawValue) has \(mode.howItPlaysBeats.count) beats, expected 3")
    }
}
```

Plus a few **verbatim exemplars** pinned with exact equality — a future content pass must change those deliberately, not by accident.

Template: `templates/ContractPinTests.swift`

## Process

### Phase 1: Identify the Invariant

Read CLAUDE.md / APP.md / file-header comments for hard rules currently enforced by nothing. Good candidates state a *set or bound*: "only", "never", "exactly", "at most", "every".

### Phase 2: Pick the Pattern

| The rule is about… | Pattern |
|---|---|
| Which files may use a framework/API | 1 — import-boundary scan (+ API-surface companion) |
| What a code path may *do* at runtime | 2 — runtime sentinel |
| A size, format, or exact content | 3 — contract pins |

### Phase 3: Write the Suite

Copy the matching template into the existing unit-test target and adapt. One suite per invariant; name it after the guarantee (`OfflineGuaranteeTests`), not the mechanism. Every failure message must tell the fixer **which side to change** — the code or the contract — and where the contract is documented.

### Phase 4: Prove It Red (Deliberate-Break Drill)

A fitness function that has never failed is unverified. Before committing:

1. Introduce the violation for real (add the forbidden import to one file; change a pinned count).
2. Run the suite — it MUST fail, with a message that names the offender.
3. Revert. Run again — green.

Record the red/green pair in the commit message or PR. Repeat the drill whenever the suite's scanning logic (not its data) changes.

### Phase 5: Commit

The suite ships in the normal test target. No special CI wiring — every existing `test` gate now enforces the rule.

## Output Format

```markdown
## Fitness Function: [invariant]

- **Rule source**: CLAUDE.md hard rule N / [file header]
- **Pattern**: import-boundary | runtime sentinel | contract pin
- **Suite**: Tests/[Name]Tests.swift
- **Deliberate-break drill**: [what was broken] → failed with "[message]" → reverted → green
```

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| `contains("import X")` matching | Comments about the rule count as violations | Compare exact trimmed lines |
| Hardcoded source paths | Breaks on other checkouts/CI | Derive root from `#filePath` |
| Pinning counts without history | Updating the pin becomes a mindless chore | Comment trail explaining every number |
| Import check only | Direct API calls bypass the fence | Add the API-surface companion scan |
| Never proven red | Scan bug silently passes everything | Deliberate-break drill before commit |
| Allowlist grows without comment | Fence decays into a headcount | Each entry documents why it's inside the boundary |

## References

- `testing/tdd-bug-fix/` — prove-red discipline for behavioral bugs
- `testing/test-contract/` — runtime behavioral invariants across implementations
- `swift/code-size/` — the complexity/size half of the deterministic gauntlet
- `testing/coverage-ratchet/` — coverage floor that only rises
