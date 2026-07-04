---
name: foundation
description: Foundation framework skills — AttributedString patterns for rich text formatting, alignment, selection, and SwiftUI integration. Use when working with styled text or AttributedString APIs.
allowed-tools: [Read, Glob, Grep]
---

# Foundation Skills

Foundation framework patterns for Apple platforms.

## When This Skill Activates

Use this skill when the user:
- Works with **AttributedString** (formatting, attributes, runs)
- Needs **rich text** alignment, selection, or styling logic
- Integrates attributed text with **SwiftUI**

## Available Skills

Paths are relative to THIS file's directory — skills run with cwd set to the
user's project, so resolve each path from this SKILL.md's own location.

| Skill | Read | Covers |
|-------|------|--------|
| attributed-string | `attributed-string/SKILL.md` | AttributedString formatting, alignment, selection, SwiftUI integration |

## How to Route

1. Read `attributed-string/SKILL.md` (relative to this file) plus any reference files it lists.
2. Apply the guidance to the user's code. For TextEditor-based rich text editing UI, see also `../swiftui/text-editing/SKILL.md`.
