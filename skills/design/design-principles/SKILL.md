---
name: design-principles
description: The evergreen Apple design canon — wayfinding, feedback, mental models, progressive disclosure, fluid gesture physics, discoverability, and the idea→interface process — distilled from Apple's design sessions (2017–2026). Use when designing a new screen or app structure, reviewing UX quality beyond HIG-compliance mechanics, fixing "users can't find X," or deciding information architecture.
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Design Principles

The principles Apple's designers repeat across a decade of sessions — the ones that survive
every visual redesign. `ios/ui-review` checks HIG mechanics; this skill is the layer above:
does the design *work*?

## When This Skill Activates

- Designing a new app's structure or a new screen from scratch
- "Users can't find the feature" / discoverability complaints
- Reviewing UX quality: navigation confusion, cluttered screens, unclear hierarchy
- Deciding what goes in the tab bar, what gets a modal, what hides behind disclosure
- Gesture/animation interactions that feel wrong but pass technical review

## The three wayfinding questions (Apple's most-repeated test)

Every screen must immediately answer — verbatim across Apple's 2017 and 2025 sessions:

1. **Where am I?**
2. **What can I do here?** / What will I find when I get there?
3. **Where can I go from here?**

A screen title + toolbar with screen-specific actions answers all three at once. If a tester
can't answer them in two seconds, the screen fails regardless of how it looks.

## The five modern principles (WWDC26)

| Principle | The test |
|---|---|
| **Purpose** | Every feature asks for the user's time, attention, and trust — does this one earn it? Ask for personal data only at the moment it's needed, never at launch. Remove features whose safety risks outweigh their value. |
| **Agency** | Users can undo anything, confirm destructive actions ("double-check it's what they actually mean"), rearrange/hide controls they don't use. |
| **Familiarity** | Things that look the same behave the same. Actions live in the same location across screens and devices. Metaphors neither too literal nor too abstract (trash can = delete, only delete). |
| **Craft** | "The uncompromising attention to detail that tells people you really care" — hierarchy via order, spacing, and contrast; plain language; platform-appropriate depth (iPhone = quick touch, Mac = deep pointer workflows). |
| **Delight** | "Delight isn't confetti" — it's the byproduct of getting the other four right. |

## The classic mechanics (Essential Design Principles)

- **Feedback** answers: what can I do · what just happened · what is happening · what will happen.
- **Mental model**: interfaces matching what users already believe are perceived as "intuitive."
- **Proximity & grouping**: the closer a control sits to what it affects, the stronger the assumed connection.
- **Affordances & mapping**: controls should resemble and be arranged like the things they change.
- **Progressive disclosure**: simple first, complexity behind a tap "waiting to become relevant."
- **80/20**: de-emphasize the rarely used 80% of features; the visible 20% does the work.

## Fluid interaction physics (Designing Fluid Interfaces)

- **Respond instantly** — latency reads as disconnection. Content tracks the finger 1:1.
- **Interruptible always**: gestures can be redirected mid-flight; "thought and gesture happen in parallel." Never lock out input because an animation is running.
- **Hysteresis**: require a movement threshold before committing to a directional gesture — "usually 10 points in iOS."
- **Soft boundaries**: rubber-band at edges, never a hard stop.
- **Project momentum**: land thrown objects using velocity + deceleration, not just position.
- **Springs over durations**: tune with damping (overshoot) + response (speed); implementation patterns in `design/animation-patterns`.

## Discoverability rules (Discoverable Design)

- Essential features are **immediately visible**; only non-essentials may hide behind navigation.
- ❌ Hamburger menus for primary features — "people don't know what's inside." Tab bars win.
- ❌ Over-minimalism: "the most minimal user interfaces might not be usable… people won't know what to do."
- ✅ Label ambiguous icons — even recognizable icons are vague without text.
- ✅ Solve the blank page: empty states show examples of possible input (also a UX-writing job — `design/ux-writing`).
- ✅ Custom gestures are **accelerators only** — a visible primary path to the same action must exist.
- ✅ Teach in context with animation, not upfront tutorials (`generators/tipkit-generator` for the mechanics).

## The idea→interface process (WWDC25)

1. **Inventory** everything the app does — features, workflows, nice-to-haves — before judging.
2. **Remove** the non-essential; **rename** the unclear (see `design/ux-writing`); **group** what belongs together.
3. **Simplify the tab bar ruthlessly** — every extra tab is another decision. Tabs are content categories, never actions (per HIG: no "Add" tab — primary actions live in the content screen).
4. Give each screen a **title + toolbar of screen-specific actions** (wayfinding + capability in one).
5. Group content by time, seasonality, progress, or patterns; prefer List over Grid for scannable, structured info.
6. Use **system text styles** (Dynamic Type free) and **semantic colors** ("label", "secondarySystemBackground" — named by purpose, not appearance; dark mode and contrast adapt automatically).

## Output Format

When reviewing a design against this skill, report per screen:

```
Screen | Wayfinding (3 Qs pass?) | Principle violations | Discoverability risks | Fix
```

ordered by user impact, each fix routed: structure → this skill; copy → design/ux-writing;
HIG mechanics → ios/ui-review or macos/ui-review-tahoe; motion → design/animation-patterns;
material/layout → design/liquid-glass.

## References

- https://developer.apple.com/videos/play/wwdc2026/250/ (Principles of great design)
- https://developer.apple.com/videos/play/wwdc2017/802/ (Essential Design Principles)
- https://developer.apple.com/videos/play/wwdc2018/803/ (Designing Fluid Interfaces)
- https://developer.apple.com/videos/play/wwdc2021/10126/ (Discoverable design)
- https://developer.apple.com/videos/play/wwdc2025/359/ (Design foundations from idea to interface)
- https://developer.apple.com/design/human-interface-guidelines/
- Related skills: `design/ux-writing`, `design/liquid-glass`, `design/animation-patterns`, `ios/ui-review`, `ios/navigation-patterns`
