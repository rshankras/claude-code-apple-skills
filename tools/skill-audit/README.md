# skill-audit — blind-test audit harness

Answers one question per skill: **does this skill teach the runtime model
anything it doesn't already know?** For each leaf skill it derives blind-test
questions, asks them to a *bare* Claude session (no CLAUDE.md, no rules, no
skills, no tools), grades the bare answers against claims extracted from the
skill, and classifies the skill. The output is a human-approval report —
**this tool never deletes or edits a skill.**

A skill earns its place by encoding at least one of:
(a) something the model gets wrong, (b) something the model can't know
(post-cutoff APIs, review lore), (c) an opinionated choice. Skills that are
none of these are DELETE/TRIM candidates.

## Verdicts

| Verdict | Meaning |
|---|---|
| `DELETE-candidate` | Bare model covered ≥0.80 of claims, no contradictions/suspects, and an Opus second-opinion regrade agreed. Human approves before anything happens. |
| `TRIM` | Coverage 0.50–0.80 — keep only the deltas the bare model missed. |
| `TRIM(prose)` | Track B only: the generator's prose guidance is redundant; templates untouched. |
| `KEEP` | Coverage <0.50 — the skill demonstrably teaches things the model lacks. |
| `FIX` | The skill itself looks wrong: a suspect claim confirmed against `scripts/api-symbols.txt` / `versions.env`, or a high-confidence contradiction where the model is right. |
| `SKIPPED-router` / `SKIPPED-error` | Category index / pipeline error (errors retry on the next run). |

## Two tracks

- **Track A (92 advisory/workflow skills):** full pipeline — derive claims+questions
  → bare answers → evidence-validated grading → verdict math in code (the judge
  model never classifies). Coverage = (covered + 0.5·partial) / gradable claims.
- **Track B (69 skills: all `generators/` + six `product/*-spec` document
  generators, see `config.json` `track_overrides`):** their value is opinionated
  templates, which a Q&A blind test cannot judge — a bare model can *talk* about
  paywalls fine. Track B grades **prose guidance only** (2 calls/skill) and can
  never emit DELETE. Template compilability is owned by
  `scripts/check-swift-templates.sh`, not this tool.

Skill enumeration reuses `scripts/check-counts.sh`'s exact counting rule
(161 skills = leaf dirs + `CATEGORY_LEVEL_SKILLS`).

## Isolation

Bare calls run with `--safe-mode --setting-sources "" --strict-mcp-config
--tools "" --disable-slash-commands` in an empty scratch cwd. A **preflight
canary** runs before every batch (ping + "list your context: NONE" probe +
a leak probe against distinctive lines from the local `~/.claude/CLAUDE.md`)
and aborts the run if isolation fails — e.g. after a CLI update changes
`--safe-mode` semantics.

## Run-book

```bash
python3 tools/skill-audit/audit.py preflight              # isolation canary (3 calls)
python3 tools/skill-audit/audit.py list                   # enumeration + track split, no calls
python3 tools/skill-audit/audit.py run --category testing # one category (recommended batch size)
python3 tools/skill-audit/audit.py run --skill ios/ui-review --skill ios/ipad-patterns
python3 tools/skill-audit/audit.py run --all              # everything (resumable, ~750 calls)
python3 tools/skill-audit/audit.py run --all --dry-run    # show selection, no calls
python3 tools/skill-audit/audit.py report                 # regenerate report from state, no calls
python3 tools/skill-audit/audit.py diff --against <old-model-id>
```

- **Resume:** re-issue the same `run` — per-question state under
  `results/<model-id>/state/` skips finished work; a kill loses at most one call.
  `--force` discards state for the selection (e.g. after editing a skill —
  content-hash changes also invalidate automatically).
- **New model release:** re-run everything; results land in a fresh
  `results/<new-model-id>/` dir, then `diff --against` the previous one.
- **Cost:** ~750 calls for a full run (≈1.5–2 h at concurrency 4; ~$35–50 if
  API-key funded, or a large slice of a subscription window).
  `max_calls_per_run` in `config.json` (default 400) hard-caps a single
  invocation — a full pass takes 2–3 invocations by design.

## What gets committed

`results/<model-id>/AUDIT-REPORT.md` + `summary.json` (the record).
`state/`, `raw/` transcripts, and `tmp-cwd/` are gitignored — bulky and
reproducible.

## Reading the report

- Per-category tables: verdict, coverage, the failed questions (the evidence a
  KEEP earns its keep), 1-line justification, flags.
- `human-review:*` flags: borderline coverage (±0.05 of a threshold), unclear
  contradictions, unverified suspects — read these rows yourself.
- `workflow-heavy`: Q&A under-samples process orchestration; don't DELETE these
  on coverage alone.
- **Appendix B (DELETE dossiers)** is the approval surface: every covered claim
  with the grader's evidence quotes, the Opus escalation outcome, and any
  SwiftShip references (`⚠️ referenced by SwiftShip` rows need a paired
  SwiftShip PR before deletion).

## Relationship to existing checks

Complements — does not replace — the structural auditor
(`skills/shared/skill-auditor`, C-01…L-03) and the CI tripwires
(`check-freshness.sh`, `check-api-symbols.sh`, `check-swift-templates.sh`).
This tool judges *content redundancy and staleness against a live model*;
those judge structure, recency claims, and API existence deterministically.
