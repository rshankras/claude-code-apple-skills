---
name: visionos
description: visionOS skills — spatial design (layout ergonomics, eyes-and-hands input, motion comfort, immersion, environments) and widget patterns (mounting styles, glass/paper textures, proximity-aware layouts). Use when designing, building, or reviewing anything for visionOS.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# visionOS Skills

Spatial-computing patterns for visionOS.

## When This Skill Activates

Use this skill when the user:
- Designs, builds, or reviews any **visionOS app, window, volume, or immersive space**
- Asks about **spatial layout, eye/hand input, hover effects, motion comfort, or environments**
- Builds or adapts **widgets for visionOS**
- Asks about **mounting styles**, glass/paper **textures**, or spatial widget families
- Needs **proximity-aware layouts**

## Available Skills

Paths are relative to THIS file's directory — skills run with cwd set to the
user's project, so resolve each path from this SKILL.md's own location.

| Skill | Read | Covers |
|-------|------|--------|
| spatial-design | `spatial-design/SKILL.md` | Layout ergonomics (60pt eye targets, dynamic scale), input, motion comfort, immersion strategy, spatial sound, video formats; `immersive-environments.md` for production budgets |
| widgets | `widgets/SKILL.md` | Mounting styles, glass/paper textures, proximity-aware layouts, spatial families |

## How to Route

1. Read `widgets/SKILL.md` (relative to this file) plus any reference files it lists.
2. Apply the guidance to the user's code.
