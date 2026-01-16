---
name: shared
description: Platform-agnostic skills including skill creation templates and best practices. Use when creating new skills or improving existing ones.
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# Shared Skills

Platform-agnostic skills that work across iOS, macOS, and other Apple platforms. This category provides foundational tools for extending Claude Code's capabilities.

## When This Skill Activates

Use this skill when the user:
- Wants to create a new Claude Code skill
- Asks about skill structure or organization
- Wants to improve or refactor existing skills
- Needs help with skill modularization
- Asks about skill best practices or templates

## Available Modules

Read relevant module files based on the user's needs:

### skill-creator/
Templates and guidance for creating well-structured Claude Code skills.
- Skill structure and organization patterns
- YAML front matter configuration
- Modularization strategies
- Templates for simple and complex skills
- Best practices and common pitfalls

## How to Use

1. Identify user's need from their question
2. Read relevant module files from subdirectories
3. Apply the guidance to their specific context
4. Provide examples from existing skills when helpful

## Example Workflow

**User wants to create a new skill:**
1. Read `skill-creator/SKILL.md` for the full creation process
2. Determine skill complexity (simple vs modularized)
3. Guide through front matter, structure, and content
4. Reference existing skills as examples
