---
name: skill-auditor
description: Audits skills in this repo for consistency, API drift, and structural gaps. Produces a prioritized report grouped by severity (Critical/High/Medium/Low). Use when asked to "audit skills", "check the skill repo for drift", or when planning bulk skill cleanup. Read-only — does not apply fixes.
allowed-tools: [Read, Glob, Grep, Bash]
---

# Skill Auditor

Audits every `SKILL.md` in `skills/` for frontmatter correctness, structural completeness, API/version drift, and cross-file reference integrity. Produces a prioritized markdown report. Read-only — never applies fixes.

## When This Skill Activates

Use this skill when the user:
- Says "audit skills", "audit my skills", "run the skill auditor"
- Asks to "check the skill repo for drift", "review skills for consistency"
- Says "find broken skills", "validate skill frontmatter"
- Is planning a bulk cleanup of the skill repo
- References a specific category to audit (e.g., "audit the generators/ skills")

**Does NOT activate** for: creating new skills (use `skill-creator`), applying fixes (follow-up flow after this auditor reports), or auditing Swift code inside skills (use `ios/coding-best-practices` or `macos/coding-best-practices`).

## Scope

Resolve the invocation argument in this order:

1. **No argument** → audit all of `skills/**/SKILL.md`
2. **Category path** (e.g., `generators/`, `ios/`) → audit `skills/<arg>/**/SKILL.md`
3. **Single file path** (e.g., `skills/liquid-glass/SKILL.md`) → audit one file
4. **Fuzzy match** → if arg doesn't resolve, try `skills/<arg>/SKILL.md`; fall back to asking the user

## Process

### 1. Enumerate

Use `Glob` with pattern `skills/**/SKILL.md` from the repo root. Filter by scope if an argument was passed. Record the canonical file list — every subsequent step operates on this list.

### 2. Parse Frontmatter (Cached)

Read the first 15 lines of each `SKILL.md`. Parse:
- Whether `---` frontmatter block exists
- `name:`, `description:`, `allowed-tools:` field values

Cache this result. Checks C-01, H-01, H-03, L-02 all read from this cache — do not re-read.

### 3. Run Checks

Execute bulk `Grep` passes in parallel (single tool-call batch) wherever possible. Per-file operations come after. The 11 checks are in the table below; the order is as-listed.

### 4. Classify Aggregator vs Leaf

For each file, mark it as **aggregator** or **leaf** using the rules in the "Aggregator Detection" section below. Some checks relax for aggregators.

### 5. Rank and Emit

Group findings by severity (🔴 → 🟢), sort within each group by file path, print the report inline using the template in "Output Format".

## Checks

### 🔴 Critical

**C-01 · Missing frontmatter.** The file has no leading `---` YAML block.
- **Detection**: multiline `Grep` for `\A---\n[\s\S]*?\n---` across all SKILL.md. Files with no match → C-01.
- **Fix**: Add YAML frontmatter with `name`, `description`, `allowed-tools`.

### 🟠 High

**H-01 · Missing `allowed-tools` field.** Frontmatter exists but `allowed-tools:` key is absent.
- **Detection**: from cached frontmatter parse.
- **Fix**: Add `allowed-tools: [Read, Glob, Grep]` (adjust based on what the skill actually does).

**H-02 · Broken supporting-file reference.** The SKILL.md references a `*.md` file that does not exist on disk in the same directory.
- **Detection**: `Grep` each SKILL.md for `[a-z0-9][a-z0-9-]*\.md` matches; resolve each relative to the SKILL.md's directory; `ls` to confirm. Missing files → H-02. Ignore matches inside fenced code blocks.
- **Fix**: Create the file or remove the reference.

**H-03 · H1 title does not match `name:`.** The first `#` heading after the frontmatter, slugified (lowercase, spaces → `-`), differs from the `name:` field.
- **Detection**: from cached frontmatter parse + per-file line-after-frontmatter.
- **Fix**: Rename the H1 or the `name:` to match.

### 🟡 Medium

**M-01 · Missing "When This Skill Activates" section.** No `## When This Skill Activates` heading anywhere in the file.
- **Detection**: `Grep -L` for `^## When This Skill Activates` across all SKILL.md.
- **Fix**: Add section with 3–5 user trigger phrases. See `shared/skill-creator/SKILL.md` for the canonical format.

**M-02 · Outdated version reference (drift).** Mentions iOS 17–25, macOS 13–25, or Swift 5.x with **drift context** (treated as current/latest/target).
- **Detection (two-stage)**:
  1. **Stage 1** — `Grep` for `\biOS (1[7-9]|2[0-5])\b|\bSwift 5\.\d+\b|\bmacOS (1[3-9]|2[0-5])\b`, capturing line numbers.
  2. **Stage 2** — for each hit, examine ±2 surrounding lines. Classify:
     - **Flag M-02** if surrounding lines contain: `latest`, `newest`, `current`, `target`, `deployment target`, `requires`, `minimum`, `as of`, `new in`, `now supports`, `today`
     - **Suppress** if surrounding lines contain: `legacy`, `pre-`, `prior to`, `before`, `deprecated`, `old`, `migrate from`, `backport`, `fallback`, `if available`, `#available`, or the version mention has a trailing `+` (e.g., `iOS 17+`)
     - **Neither** → L-03 (ambiguous)
- **Known-current constants** (dated 2026-07-11, update per WWDC): iOS 27, macOS 27 (announced WWDC26; iOS 26 / macOS 26 are within the one-generation grace), Swift 6.x. Normative source: `scripts/versions.env`. Mentions of these with drift context are always clean.
- **Fix**: Update the reference to the current generation (see `scripts/versions.env`), or annotate as legacy context with one of the suppression keywords.

**M-03 · Pre-`@Observable` pattern without deprecation callout.** Uses `@StateObject` or `ObservableObject` without acknowledging that `@Observable` is the current pattern.
- **Detection**: `Grep` for `@StateObject|ObservableObject` with line numbers; for each hit, secondary `Grep` of the same file for `@Observable|deprecated|legacy|pre-@Observable|migration|old pattern` within ±10 lines. No secondary match → M-03.
- **Fix**: Either replace with `@Observable` + `@State`, or add a migration note explaining why the older pattern is shown.

**M-04 · Oversized single-file skill.** `SKILL.md` exceeds 400 lines and its directory contains no sibling `.md` files.
- **Detection**: `wc -l` via Bash on each SKILL.md; if `>400`, check sibling file list via `ls` for any other `.md`. None → M-04.
- **Fix**: Modularize — extract sections into `patterns.md`, `templates.md`, `checklist.md`, or `examples.md` per `skill-creator` conventions.

### 🟢 Low

**L-01 · No ✅/❌ examples in prose.** The file has no `✅` or `❌` markers anywhere.
- **Detection**: `Grep -L` for `✅|❌`.
- **Fix**: Add at least one good/bad example pair.

**L-02 · Description length out of range.** `description:` is <20 or >300 characters.
- **Detection**: from cached frontmatter parse.
- **Fix**: Expand or shorten the description. Include a "use when…" clause to anchor activation.

**L-03 · Ambiguous version mention.** A version keyword matched stage 1 of the drift check but surrounding lines contained neither drift nor legacy context. User reviews manually.
- **Detection**: fallthrough from M-02 stage-2 classification.
- **Fix**: Add a drift or legacy keyword to disambiguate, or leave as-is if the context is clearly a one-off mention.

## Aggregator vs Leaf Detection

A SKILL.md is an **aggregator** if any of the following hold:
- It sits at depth 2 under the repo root — i.e., `skills/<category>/SKILL.md`
- It contains the heading `## Available Modules` or `## Available Skills`
- It links to `./<subdir>/SKILL.md` or contains two or more references of the form `skills/<category>/<subskill>/`

Otherwise it is a **leaf**.

### Relaxations for aggregators

| Check | Behaviour |
|---|---|
| M-01 (activation section) | Still enforced — aggregators must describe activation |
| M-03 (pre-@Observable) | Suppressed — aggregators are prose, not code |
| M-04 (>400 lines) | Suppressed — aggregators are allowed to be long when enumerating modules |
| L-01 (no ✅/❌ examples) | Suppressed — aggregators don't carry patterns |

Tag every finding in the report with `(aggregator)` or `(leaf)` so severity can be read at a glance.

## Output Format

Print the report inline to the conversation using this template. Use exact headings — downstream tooling may grep them.

```markdown
# Skill Audit Report — <YYYY-MM-DD> — <N> files scanned

## Summary
- 🔴 Critical: <count>
- 🟠 High: <count>
- 🟡 Medium: <count>
- 🟢 Low: <count>
- ✅ Files clean: <clean-count> / <N>

Scope: <all | category | single file>

## 🔴 Critical Findings
### C-01 · Missing frontmatter
- `skills/<path>/SKILL.md` (leaf) — **Fix:** Add YAML frontmatter with `name`, `description`, `allowed-tools`.

## 🟠 High Findings
### H-01 · Missing `allowed-tools` field
- `skills/liquid-glass/SKILL.md:1-4` (leaf) — **Fix:** Add `allowed-tools: [Read, Glob, Grep]`.
- `skills/macos/macos-tahoe-apis/SKILL.md:1-4` (leaf) — **Fix:** Same.

### H-02 · Broken supporting-file reference
- `skills/<path>/SKILL.md:<line>` — references `patterns.md`, not found. **Fix:** Create the file or remove the reference.

### H-03 · H1 title does not match `name:`
- `skills/<path>/SKILL.md` — `name: foo-bar`, H1 is `# Foo Bars`. **Fix:** Rename one to match.

## 🟡 Medium Findings
### M-01 · Missing "When This Skill Activates" section (<count>)
- `skills/design/liquid-glass/SKILL.md` (leaf)
- `skills/macos/coding-best-practices/SKILL.md` (leaf)
- [collapsed list of remaining offenders]
- **Fix:** Add section with 3–5 user trigger phrases.

### M-02 · Outdated version reference (<count>)
- `skills/<path>/SKILL.md:87` (leaf) — "latest iOS 17" in drift context. **Fix:** Update to iOS 26.

### M-03 · Pre-`@Observable` pattern without callout (<count>)
- `skills/<path>/SKILL.md:142` (leaf) — `@StateObject` without migration note. **Fix:** Replace with `@Observable` or add callout.

### M-04 · Oversized single-file skill (<count>)
- `skills/<path>/SKILL.md` — <NNN> lines, no sibling .md files. **Fix:** Modularize into `patterns.md` / `templates.md`.

## 🟢 Low Findings
### L-01 · No ✅/❌ examples
- `skills/<path>/SKILL.md` (leaf) — **Fix:** Add at least one good/bad example pair.

### L-02 · Description length out of range
- `skills/<path>/SKILL.md` — description is <N> chars. **Fix:** Expand/shorten to 20–300 chars.

### L-03 · Ambiguous version mention
- `skills/<path>/SKILL.md:<line>` — "iOS 18" with no drift/legacy context. **Fix:** Review manually.

## ✅ Clean Files
<collapsed list of files that passed all checks>

## Next Steps
- Review 🔴/🟠 findings first — they block skills from working as intended.
- Batch-fix 🟡 M-01 and M-02 mechanically — suggested find/replace scripts shown per-file.
- 🟢 findings are polish; address opportunistically.
```

## Implementation Notes

- **Parallelize bulk Greps** in a single tool-call batch where possible. Activation, frontmatter, `@StateObject`, and drift-stage-1 can all run at once.
- **Cache the frontmatter parse.** Four checks read it; only parse once.
- **Resolve `*.md` references inside fenced code blocks carefully** — they're examples, not references. Strip fenced blocks before running H-02's regex.
- **Progress pings** — for full-repo scans (148 files), emit a short "scanning <N>/<total>…" before each phase so the user sees liveness.
- **Idempotence** — the report body (everything below the `## Summary`) should be deterministic for a given repo state. Only the date in the H1 varies across runs.
- **Never write files.** This skill's `allowed-tools` lists Bash, but only for read-only ops (`wc`, `ls`). If you find yourself needing to write, stop and ask the user to invoke a fix flow separately.

## Non-Goals

- **No auto-fix.** The report includes one-line fix suggestions per finding; applying them is a separate user-initiated task.
- **No network calls.** This auditor does not verify URL liveness or check Apple doc availability.
- **No Swift compilation.** Code-block validity is beyond scope; patterns are matched textually.
- **No WWDC session cross-referencing.** A future `wwdc-to-skill-workflow` skill owns that.

## Relationship to CI

CI (`scripts/check-freshness.sh`) owns the deterministic subset of M-02: a recency keyword AND a stale version (major ≤ current−2) on the **same line** is a blocking build failure. This auditor's M-02 remains the broader net — ±2-line context, `current`/`target`/`requires` keywords, human-reviewed. Findings unique to M-02 are review candidates, not CI failures; anything CI already blocks will never appear here because it can't merge. C-01 is likewise fully delegated: `scripts/check-frontmatter.sh` blocks missing frontmatter at PR time.

## Maintenance

The drift heuristic hardcodes "known-current" version constants:

- iOS 27, macOS 27, Swift 6.x (dated 2026-07-11; announced WWDC26)

**Update these constants** when Apple ships a new major platform version (usually post-WWDC each June), together with `scripts/versions.env` — CI's `check-freshness.sh` cross-checks that this file mentions the manifest's current iOS generation and fails if they drift apart. The stage-1 regex ranges (`iOS 1[7-9]|2[0-5]`, `macOS 1[3-9]|2[0-5]`) must also be widened each cycle so their upper bound stays at CURRENT−2 (the previous generation sits inside a one-generation grace and is not stale; the ranges are unchanged for the iOS 27 cycle since 17–25 already ends at 27−2).

## Verification

After running the auditor on the full repo, counts should fall within this tolerance band (baseline re-taken 2026-07-11, 165 total `SKILL.md` files scanned — 142 leaf skills + 23 category indexes; the README's "147 skills" counts leaf dirs plus the 5 single-skill categories):

| Finding | Expected |
|---|---|
| C-01 missing frontmatter | **0** — the 2026-04 legacy batch was fixed, and `scripts/check-frontmatter.sh` now blocks regressions in CI |
| H-01 missing `allowed-tools` | **0** |
| H-02 broken supporting refs | 0 |
| H-03 H1 mismatch | flag outliers manually |
| M-01 missing activation section | **6** — ui-prototyping, iap-finalizer, originality-check, store-signals, flow-walkthrough, privacy-publish |
| M-02 version drift | stage-1 Grep returns ~369 raw hit lines across ~147 files (2026-07-11); the stage-2 narrowed band must be re-derived on the next full run — the pre-hardening band (~50±10) was measured against ~228 raw hits, and CI's `check-freshness.sh` has since removed the same-line recency subset |
| M-03 pre-`@Observable` no callout | ~29 (±5) — re-verify on the next full run |
| M-04 oversized single-file | TBD — flag outliers |

### Known legacy pattern: `## When to Use` (resolved)

The 2026-04 batch of files using `## When to Use` as their activation heading has been fully normalized — as of 2026-07-11 no SKILL.md uses it in place of the canonical heading. The rule stands for future contributions: do **not** widen the M-01 regex to accept `## When to Use` — the whole point is to normalize onto the canonical heading. (A `## When to Use …` heading deeper in a file as *content* — e.g. `swift/memory`'s "When to Use / When NOT to Use" section about the technique itself — is fine and not an M-01 signal.)

### Smoke tests

1. **Full-repo run** — invoke with no arg. Counts must fall within tolerance above.
2. **Scoped run** — invoke with `generators/`. Only `skills/generators/**` paths appear.
3. **Single-file run** — invoke with `skills/liquid-glass/SKILL.md`. Report has exactly one H-01 finding.
4. **Idempotence** — re-run immediately. Report body is byte-identical; only the date in the H1 may differ.
5. **Drift heuristic sanity** — spot-check 5 M-02 hits and 5 suppressed legacy mentions. If any legacy mention is mis-flagged, extend the suppression keyword list and re-run.

## References

- `../../../CLAUDE.md` (repo root, resolved relative to this SKILL.md — not the project cwd) — normative source for frontmatter schema, naming, emoji convention. If absent (skills-only copies), use https://github.com/rshankras/claude-code-apple-skills/blob/main/CLAUDE.md
- `skills/shared/skill-creator/SKILL.md` — companion meta-skill for creating new skills (this auditor only audits; it does not create)
- `skills/ios/SKILL.md` — canonical aggregator example
