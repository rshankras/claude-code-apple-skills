# Quick Start Guide

Get up and running with Claude Code Apple Skills in under 5 minutes!

## Prerequisites

- Claude Code installed
- iOS/macOS/Swift project with `.claude/` directory

## Installation (1 minute)

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
# Just generators (21 skills)
cp -r /path/to/claude-code-apple-skills/skills/generators .claude/skills/

# Just testing/TDD (8 skills)
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

## Skill Categories (83 total)

| Category | Count | Purpose |
|----------|-------|---------|
| `generators/` | 21 | Production-ready code for common features |
| `product/` | 11 | Idea to App Store workflow |
| `testing/` | 8 | TDD workflows, test infrastructure |
| `macos/` | 8 | macOS development patterns |
| `ios/` | 7 | iOS code review, UI review, planning |
| `swiftui/` | 5 | AlarmKit, WebKit, text editing, toolbars, Charts 3D |
| `app-store/` | 4 | ASO, descriptions, keywords, reviews |
| `swift/` | 3 | Concurrency, Swift 6.2, memory |
| `apple-intelligence/` | 3 | Foundation Models, Visual Intelligence, App Intents |
| `design/` | 2 | Liquid Glass, animations |
| `performance/` | 2 | Instruments, SwiftUI debugging |
| `security/` | 2 | Keychain, biometrics, privacy manifests |
| `monetization/` | 1 | Pricing strategy, tiers, free trials |
| `watchos/` | 1 | Watch apps, complications |
| + 5 more | 5 | SwiftData, MapKit, Foundation, visionOS, Release Review |

## Troubleshooting

### Skill Not Activating

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
