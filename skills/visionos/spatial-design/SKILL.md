---
name: spatial-design
description: Designing for visionOS — spatial layout and ergonomics (60pt eye targets, field-of-view placement, dynamic scale), eyes-and-hands input with hover rules, motion and visual comfort (the 0.2 Hz rule, vection, depth-cue agreement), immersion strategy, spatial sound, and the video-format decision guide. Use when designing or reviewing any visionOS app, window, volume, or immersive experience.
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Spatial Design (visionOS)

The design rules that make a visionOS app comfortable instead of exhausting — distilled from
Apple's spatial-design sessions (WWDC23–26). Widget-specific rules live in `visionos/widgets`;
custom immersive-environment production and budgets live in `immersive-environments.md`.

## When This Skill Activates

- Designing or reviewing a visionOS app, window, volume, or immersive space
- "Users say it's tiring / uncomfortable / hard to hit controls"
- Porting an iPad app and deciding what should become spatial
- Adding hover effects, custom gestures, environments, or spatial audio
- Choosing a video experience format (spatial, 180°, 360°, wide-FOV, Apple Immersive)

## The prime directive: find the key moment

Don't window a 2D app. Identify the one thing only possible on visionOS — the "key moment" —
and build around it. Immersion has three approaches, and full immersion is not mandatory:
full environments · integration with real surroundings (scene sensing) · meaningful audio.

## Layout & ergonomics

- **Wide beats tall** — layouts match the human field of view; turning the head left/right is
  easier than up/down. Center = primary content; edges = secondary, infrequent actions.
- Default placement sits along the natural line of sight, a bit **further than arm's reach**;
  extended reading goes farther out, centered and slightly below eye line.
- **Design in points, not meters** — dynamic scale keeps windows legible at any distance
  (they scale up as they move away). Never fixed scale for UI; keep custom UI facing the viewer.
- **Depth is hierarchy, used sparingly** — "prefer subtle depth" (a modal pushes its parent
  back). Keep text flat; 3D text is hard to read at an angle.
- **Glass, never solid** window backgrounds — solid colors block the world, don't adapt to
  lighting, and "can feel constricting." Elements on glass use vibrancy + white text/symbols;
  system colors over custom (they're calibrated for legibility). Brand color goes in
  backgrounds or whole buttons, not glyphs.
- Typography runs **heavier than iOS**: body = medium (vs regular), titles = bold (vs
  semibold), slightly increased tracking. Avoid small/lightweight custom fonts.
- Component specs: vertical tab bar fixed left, **≤6 items**, expands on gaze · ornaments
  overlap the window's bottom edge **by 20pt**, borderless buttons inside · sheets appear
  centered at the parent's Z while the parent dims and pushes back · nested corners concentric
  (outer radius = inner + padding).
- SwiftUI spatial layout: stacks default to `.back` depth alignment — switch to `.front` when
  content should read toward the viewer; `rotation3DLayout` (not `rotation3DEffect`) when
  rotation must affect layout; `SpatialContainer`/`spatialOverlay` for shared 3D space;
  `scaledToFit3D()` for models.

## Input: eyes target, hands confirm

- **Every interactive element gets ≥60pt of total target area** (≈2.5°, ~4.4cm at 1m) — the
  element can be smaller if surrounding spacing makes up the difference. Standard buttons:
  44pt + ≥8pt clearance; stacked buttons ≥16pt apart; list rows 4pt padding so hover
  effects don't overlap.
- Keep interactive content **at one depth** — frequent focus-depth changes cause eye strain.
- Eye-target shapes: circles, pills, rounded rectangles; no sharp edges or thick outlines;
  center text/glyphs with generous padding.
- **Every interactive element needs a hover effect — and only interactive elements get one**
  (never read-only data). Hover runs out-of-process: gaze stays private until a gesture.
- Hover rules (WWDC24/25): keep it subtle (a 5% scale is the reference); short delays prevent
  flicker (reveal effects: ~0.8s in / 0.2s out); effects start from a visible element — no
  invisible hotspots; high-traffic controls (toolbars, table cells) use ONLY the standard
  highlight; keep an anchoring element static; respect Reduce Motion (swap for cross-fade).
- Standard gesture language first (pinch = tap, pinch-drag = scroll, two-hand zoom/rotate).
  Custom gestures must be explainable, repeatable without fatigue, distinct from system
  gestures, and false-positive-tested; map them to real-world actions.
- Prefer **interaction at a distance** (eyes target, hands rest in lap) for long sessions;
  direct touch is for up-close manipulation — compensate for missing tactility (raise buttons,
  brighten as the finger approaches, snap state + spatial sound on contact).
- Look-to-scroll only in reading/browsing surfaces, never scan-and-pick lists; auto-hiding
  controls should persist while looked at.

## Motion & visual comfort (the failure modes)

- **Depth cues must agree** — size, blur, occlusion, shadow, texture density. Conflicts cause
  double vision and fatigue. Beware repeating patterns (eyes lock onto different repeats).
- **Vection**: large moving content that fills the view reads as self-motion → discomfort.
  Make big moving content semitransparent so passthrough anchors the viewer.
- **Avoid oscillations around 0.2 Hz** (one cycle per 5s); if unavoidable, low amplitude +
  semitransparency, and honor Reduce Motion with an oscillation-free alternative.
- **No head-locked content**; if unavoidable: small, central, far — or lazy-follow.
- Camera motion inside windows: keep the content horizon level with the real horizon; slow,
  predictable focus of expansion inside the field of view; never fast pure rotations — cut
  with a quick fade instead. Avoid close-range fly-bys.
- Moving the user or the scene: fade out during motion, fade back when settled. Design
  stationary-first — the system fades immersive content when people move.
- Eyes rotate most comfortably downward and left/right; upward/diagonal fixation is for brief
  interactions only. Slow dark→bright transitions (allow adaptation).

## Spatial sound as a design material

- Two layers: **point-source emitters** (positioned, room-matched reverb is automatic) +
  **looping ambient surround beds**. Even a windowed app may fill the room with a soundscape.
- Randomize repeats — pitch, amplitude, sample choice, position, timing. Nothing loops
  audibly from the same spot.
- Mix with distance: a few dB down AND pushed farther away = background.
- Use direction to steer attention (footsteps from the left before an entrance); attach
  multiple emitters to characters (feet omnidirectional, mouth directional).
- UI sounds: subtle — heard constantly. Match character/timing to the visual transitions.

## Interactive experiences (from Encounter Dinosaurs)

Adapt to the real room (portal up to 4m across in big rooms; set-distance + dimmed passthrough
in tiny ones) · open small and welcoming, onboard that content reacts to people · use head
position for eye contact (proximity signals interactivity; averted attention signals not) ·
consistent interaction rules — inconsistency shatters immersion · pace emotion with low-relief
breaks (nonstop interaction physically exhausts) · gentle in-world boundaries over hard
failures · accessibility is spatial too: VoiceOver, Dwell, captions, audio descriptions,
Dynamic Type.

## Video format decision guide

| You want | Use |
|---|---|
| Flat storytelling | 2D/3D/spatial video, windowed or docked (3D needs expanded) |
| "Being there," forward-facing | Stereo 180° (half-equirectangular) |
| Look-anywhere | 360° (equirectangular 2:1, typically mono) |
| Action-cam POV | Wide-FOV APMP (120–180°, parametric lens projection) |
| Premium cinematic immersion | Apple Immersive Video (8160×7200/eye @ 90fps, up to 210°×180°) |

Comfort rule: immersive playback puts the head where the camera was — high-motion scenes
auto-reduce immersion (QuickLook/AVKit/RealityKit); encode stereo as MV-HEVC, never
side-by-side. APMP formats never play inline.

## Scene behavior defaults

Prefer scene restoration (windows come back where placed); disable only for transient/welcome
windows (`restorationBehavior(.disabled)`, `defaultLaunchBehavior(.suppressed)`). Adapt
volumes to walls/tables via surface snapping info (authorization required). Handle Digital
Crown recentering (`onWorldRecenter`). Progressive immersion with an aspect ratio is a comfort
lever for vertical/high-motion content.

## Output Format

Spatial design review:

```
Area | Finding | Comfort/ergonomic rule violated | Fix
```

ordered: comfort violations (motion/depth/head-lock) first — they end sessions; then input
targets; then layout polish. Route environment production to `immersive-environments.md`,
widgets to `visionos/widgets`.

## References

- https://developer.apple.com/videos/play/wwdc2023/10072/ (Principles of spatial design)
- https://developer.apple.com/videos/play/wwdc2023/10076/ (Spatial user interfaces)
- https://developer.apple.com/videos/play/wwdc2023/10073/ (Spatial input)
- https://developer.apple.com/videos/play/wwdc2023/10078/ (Vision and motion)
- https://developer.apple.com/videos/play/wwdc2024/10086/ (Design great visionOS apps)
- https://developer.apple.com/videos/play/wwdc2025/303/ (Hover interactions)
- https://developer.apple.com/videos/play/wwdc2025/304/ (Video experiences)
- https://developer.apple.com/design/human-interface-guidelines/designing-for-visionos
- Related: `visionos/widgets`, `design/design-principles`, `design/animation-patterns`
