# Quick Start Guide

Get up and running with Claude Code Apple Skills in under 5 minutes!

## Prerequisites

- Claude Code installed
- iOS/macOS/Swift project with `.claude/` directory

## Installation (1 minute)

### Option 0: Plugin Install (recommended)

In Claude Code:

```
/plugin marketplace add rshankras/claude-code-apple-skills
/plugin install apple-skills@indie-apple-stack
```

Skills appear as 23 category skills, namespaced by plugin — invoke as
`/apple-skills:<category>` (e.g. `/apple-skills:generators`). Update with
`/plugin marketplace update indie-apple-stack`.

Some skills also ship a `rules/swiftlint.yml` fragment — deterministic lint
rules graduated from their prose. They ride along with any install; merge
them into your project's `.swiftlint.yml` (the `ci-cd-setup` generator does
this for you).

### Option 1: Full Install

```bash
# Clone the repository
git clone https://github.com/rshankras/claude-code-apple-skills.git

# Navigate to your project
cd /path/to/your/project

# Create skills directory if it doesn't exist
mkdir -p .claude/skills

# Copy all skills
cp -r /path/to/claude-code-apple-skills/skills/* .claude/skills/
```

### Option 2: Individual Categories

Copy only the categories you need:

```bash
# Just generators (63 skills)
cp -r /path/to/claude-code-apple-skills/skills/generators .claude/skills/

# Just testing/TDD (9 skills)
cp -r /path/to/claude-code-apple-skills/skills/testing .claude/skills/

# Just iOS review skills
cp -r /path/to/claude-code-apple-skills/skills/ios .claude/skills/
```

### Option 3: Global Install

Install once, available in all projects:

```bash
cp -r /path/to/claude-code-apple-skills/skills/* ~/.claude/skills/
```

## Verification (30 seconds)

Check that skills are installed:

```bash
ls .claude/skills/
# Should show: generators  ios  macos  testing  monetization  product  ...
```

Plugin installs: run `/plugin` and confirm `apple-skills` lists 23 skills.

## First Use (2 minutes)

### Just Describe What You Want

Skills activate automatically — no manual invocation needed:

| Say this... | Skill that activates |
|-------------|---------------------|
| "Review my code for best practices" | `ios/coding-best-practices` or `macos/coding-best-practices` |
| "Review my UI for HIG" | `ios/ui-review` or `macos/ui-review-tahoe` |
| "Add logging to my app" | `generators/logging-setup` |
| "Add subscription paywall" | `generators/paywall-generator` |
| "TDD this new feature" | `testing/tdd-feature` |
| "Fix this bug and add a test" | `testing/tdd-bug-fix` |
| "I need to refactor this safely" | `testing/tdd-refactor-guard` |
| "Should I monetize my app?" | `monetization` |
| "Review for release" | `release-review` |
| "I have an app idea..." | `product/product-agent` |

## Common Workflows

### New App

```
You: "I have an idea for a macOS app that does X"
→ product/product-agent validates the idea
→ product/market-research sizes the market
→ product/prd-generator creates the PRD
→ generators/ add features as you build
→ release-review/ audits before shipping
```

### Existing App — Add Features

```
You: "Add CloudKit sync to my app"
→ generators/cloudkit-sync generates the code
→ testing/tdd-feature helps you test it
```

### Existing App — Safe Refactoring

```
You: "I need to refactor my data layer"
→ testing/tdd-refactor-guard checks test coverage
→ testing/characterization-test-generator captures current behavior
→ You refactor with confidence
```

### Bug Fix

```
You: "Users report X is broken"
→ testing/tdd-bug-fix writes failing test first
→ Fix + verify + never regress
```

## Tips for Best Results

### Be Specific

```
Good: "Review ExpenseViewModel.swift for best practices"
Vague: "Check my code"
```

### Provide Context

```
Good: "Add a subscription paywall with monthly and yearly tiers"
Vague: "Add payments"
```

## Skill Categories

**159 skills across 23 categories** — see the
[What's Included table in the README](../README.md#whats-included) for the
per-category breakdown (kept in sync with the tree by `scripts/check-counts.sh`).

## Troubleshooting

### Skill Not Activating

0. Plugin installs: names are namespaced — try `/apple-skills:<category>` (e.g. `/apple-skills:testing`)
1. Check skill is in `.claude/skills/` directory
2. Verify YAML front matter is valid: `head -5 .claude/skills/testing/SKILL.md`
3. Use explicit trigger phrases from the skill's "When This Skill Activates" section
4. Try: "Use the [skill-name] skill to review this"

### Wrong Skill Activates

- Be more specific in your request
- Skills auto-select based on keyword matching in their descriptions

## Next Steps

- Browse `skills/` to see all available skills
- Read [USAGE.md](USAGE.md) for the complete usage guide
- Read [ROADMAP.md](ROADMAP.md) for skill coverage tracking
- See [CONTRIBUTING.md](../CONTRIBUTING.md) to contribute
