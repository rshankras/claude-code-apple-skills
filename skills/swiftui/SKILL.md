---
name: swiftui
description: SwiftUI framework skills — data flow (identity, Observation, state ownership), layout & containers (Layout protocol, lazy-stack performance), AlarmKit, 3D charts, rich text editing, customizable toolbars, and WebKit embedding. Use for SwiftUI state/rendering bugs, custom layouts, scroll performance, or these feature areas.
allowed-tools: [Read, Glob, Grep]
---

# SwiftUI Skills

Focused SwiftUI framework skills — each sub-skill covers one API area in depth.

## When This Skill Activates

Use this skill when the user:
- Has **state/rendering bugs**: state resets, over-rendering, flashing lists, animation crossfades (data-flow)
- Is choosing **@State vs @Bindable vs @Environment** or migrating to Observation (data-flow)
- Builds **custom layouts or containers**, or fights **lazy-stack/scroll performance** (layout)
- Wants alarms or timers with **AlarmKit** (custom UI, Live Activities, snooze)
- Is creating **3D data visualizations** with Swift Charts (Chart3D, SurfacePlot)
- Needs **styled text or rich text editing** (Text, AttributedString, TextEditor)
- Is implementing or customizing **toolbars** (customizable toolbars, search integration)
- Wants to **embed web content** (WebView, WebPage, JavaScript interop)

## Available Skills

Paths are relative to THIS file's directory — skills run with cwd set to the
user's project, so resolve each path from this SKILL.md's own location.

| Skill | Read | Covers |
|-------|------|--------|
| data-flow | `data-flow/SKILL.md` | View identity/lifetime/dependencies, Observation, state ownership, body discipline, main-actor contract |
| layout | `layout/SKILL.md` | Layout protocol, Grid decisions, custom containers, lazy-stack + scrolling performance rules |
| alarmkit | `alarmkit/SKILL.md` | Alarms and timers with custom UI, Live Activities, snooze (iOS 18+) |
| charts-3d | `charts-3d/SKILL.md` | Chart3D, SurfacePlot, interactive pose control, surface styling |
| text-editing | `text-editing/SKILL.md` | Text, AttributedString, TextEditor with formatting controls |
| toolbars | `toolbars/SKILL.md` | Customizable toolbars, search integration, transition effects, platform behavior |
| webkit | `webkit/SKILL.md` | WebView and WebPage embedding, navigation, JavaScript interop |

## How to Route

1. Match the request to a row above.
2. Read that SKILL.md (relative to this file) plus any reference files it lists.
3. Apply the guidance to the user's code.
