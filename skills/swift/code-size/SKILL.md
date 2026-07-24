---
name: code-size
description: Enforce complexity and size limits on Swift code with SwiftLint threshold rules — cyclomatic complexity, function/type/file length, parameter count — adopted via a violations baseline so existing code never blocks. Use when agent-written code needs deterministic size constraints.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
last_verified: 2026-07-24
review_by: 2027-07-01
---

# Code Size & Complexity Limits

Complexity is the strongest single predictor of defect density, and code written *by agents* balloons fastest — an agent under pressure adds one more branch to an existing function far more readily than it extracts a new one. These five SwiftLint threshold rules are the deterministic cap: they keep functions small enough that tests can actually cover their branches, and they keep agents from wrangling with their own tangles.

## When This Skill Activates

Use this skill when:
- Setting up quality gates for a project where agents write most of the code
- A review keeps flagging "this function is too long/branchy" by hand
- Functions have grown past what their tests plausibly cover
- Adopting the deterministic gauntlet (see `testing/fitness-functions/`)

## The Rules

The fragment at `rules/swiftlint.yml` configures five built-in SwiftLint rules (all enabled by default in SwiftLint — this fragment sets the thresholds):

| Rule | Warning | Error | What it caps |
|---|---|---|---|
| `cyclomatic_complexity` | 10 | 20 | Independent paths through one function |
| `function_body_length` | 50 | 100 | Lines per function body |
| `type_body_length` | 300 | 500 | Lines per type body |
| `file_length` | 500 | 1000 | Lines per file |
| `function_parameter_count` | 5 | 8 | Parameters per function |

Merge the fragment into the project's `.swiftlint.yml` (alongside any `opt_in_rules`/`custom_rules` fragments already adopted).

## Brownfield Adoption: Baseline, Never Mass-Refactor

Turning these rules on in an existing codebase must not trigger a refactoring spree — bulk rewrites to satisfy a linter are how working code gets broken. Freeze today's violations and gate only *new* ones:

```bash
# One-time: record existing violations (SwiftLint 0.55+)
swiftlint lint --write-baseline .swiftlint-baseline.json

# The gate from then on — fails only on NEW violations
swiftlint lint --strict --baseline .swiftlint-baseline.json
```

Commit `.swiftlint-baseline.json`. Shrink it opportunistically: when touching a baselined function for other reasons, fix its violation and regenerate the baseline in the same commit.

**Fallback for older SwiftLint** (before 0.55, no baseline support): record the violation count instead —

```bash
swiftlint lint --quiet | wc -l > .swiftlint-count
# Gate: current count must not exceed the committed count
```

## When a Rule Fires

The fix is structural, not suppressive:

- `cyclomatic_complexity` / `function_body_length` → extract the branches into named functions, or replace the branch ladder with a table/enum dispatch
- `type_body_length` / `file_length` → split by responsibility (extensions in separate files count separately)
- `function_parameter_count` → introduce a parameter struct

`// swiftlint:disable` is not a fix. The rare legitimate exemption (a generated file, a big-but-flat data table) belongs in `.swiftlint.yml`'s `excluded:` list with a comment — visible in one place, not scattered through source.

## Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Enabling without a baseline | Day-one wall of violations, gate ignored | `--write-baseline` first, gate on new only |
| Mass-refactoring to satisfy thresholds | Working code broken for a number | Freeze old violations; fix opportunistically |
| Inline `swiftlint:disable` comments | Exemptions scattered and invisible | `excluded:` list in config, with reasons |
| Thresholds loosened per-project | Cap quietly stops capping | Change thresholds only with a written reason |

## References

- `testing/fitness-functions/` — set/count invariants a per-line rule can't express
- `testing/coverage-ratchet/` — the coverage half of the metrics gauntlet
- `ios/coding-best-practices/` — iOS-specific lint fragment (style/API rules)
- `generators/ci-cd-setup/` — base `.swiftlint.yml` template these fragments merge into
