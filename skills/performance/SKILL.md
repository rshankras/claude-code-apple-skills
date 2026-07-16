---
name: performance
description: Performance profiling and SwiftUI debugging skills — Instruments guidance, hangs, memory issues, slow launches, energy drain, unnecessary re-renders, and view identity problems. Use when an app is slow, janky, or resource-hungry.
allowed-tools: [Read, Glob, Grep, Bash]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Performance Skills

Diagnose and fix performance problems, from system-level profiling to SwiftUI render behavior.

## When This Skill Activates

Use this skill when the user:
- Reports the app is **slow, janky, or hanging**
- Wants to profile with **Instruments** (Time Profiler, Allocations, Hangs)
- Is investigating **memory issues, slow launches, or energy drain**
- Sees SwiftUI views **re-rendering too often** or slow `body` evaluations
- Asks about **view identity** problems or `_printChanges()`

## Available Skills

Paths are relative to THIS file's directory — skills run with cwd set to the
user's project, so resolve each path from this SKILL.md's own location.

| Skill | Read | Covers |
|-------|------|--------|
| profiling | `profiling/SKILL.md` | Instruments workflows; hangs, memory, slow launch, energy diagnosis |
| swiftui-debugging | `swiftui-debugging/SKILL.md` | Unnecessary re-renders, view identity, slow body evaluations |

## How to Route

1. Match the request to a row above — system-level symptoms → profiling; SwiftUI render symptoms → swiftui-debugging.
2. Read that SKILL.md (relative to this file) plus any reference files it lists.
3. Apply the guidance to the user's code.
