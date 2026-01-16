# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a collection of Claude Code skills for Apple platform development (iOS, macOS, iPadOS). Skills are markdown files that provide domain knowledge and workflows to Claude Code instances.

**This is NOT a code project** - it contains only markdown documentation files organized as skills.

## Architecture

### Skill Structure

```
skills/
├── {category}/
│   ├── SKILL.md           # Entry point with YAML frontmatter
│   └── {sub-skill}/
│       ├── SKILL.md       # Sub-skill entry point
│       └── *.md           # Supporting reference files
```

### YAML Frontmatter (Required)

Every SKILL.md must have:

```yaml
---
name: skill-name
description: Brief description and when to use it
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---
```

### Skill Categories

| Category | Purpose |
|----------|---------|
| `ios/` | iOS development patterns |
| `macos/` | macOS development patterns |
| `product/` | Product development workflow (idea to App Store) |
| `generators/` | Code generators producing production-ready Swift |
| `apple-intelligence/` | Foundation Models, Visual Intelligence |
| `design/` | Liquid Glass, modern design patterns |
| `app-store/` | ASO, descriptions, screenshots, reviews |
| `release-review/` | Pre-release audit checklists |
| `shared/` | Templates for creating new skills |

### Generator vs Advisory Skills

- **Advisory skills** (ios/, macos/, release-review/): Review code and provide recommendations
- **Generator skills** (generators/): Produce production-ready Swift code with templates

## Creating New Skills

Use `skills/shared/skill-creator/SKILL.md` as the guide. Key requirements:

1. **Simple skills** (< 400 lines): Single SKILL.md file
2. **Complex skills** (> 400 lines): Modularize into SKILL.md + reference files
3. **Naming**: Use `kebab-case` for skill names and files
4. **Activation triggers**: Clear "When This Skill Activates" section
5. **Examples**: Always show ✅ good and ❌ bad patterns

## Apple Docs Reference

Apple documentation files are stored at `/Users/ravishankar/Downloads/docs/`. Skills should reference these for latest API patterns.

See `docs/ROADMAP.md` for planned skills based on available Apple docs.

## Conventions

- Code examples must be syntactically correct Swift
- Use emoji sparingly (✅ ❌ for patterns, priority indicators for issues)
- Output formats should use: 🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low, ✅ Strengths
- Generator templates use protocol-based architecture for swappable implementations
