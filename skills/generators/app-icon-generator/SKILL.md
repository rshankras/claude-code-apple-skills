---
name: app-icon-generator
description: Generates an app icon for macOS or iOS — a fast CoreGraphics placeholder and/or flat layered source art to finish in Icon Composer (the Liquid Glass / iOS 26+ standard). Produces appearance variants (light/dark/tinted) and installs into the asset catalog. Use when the user wants to create, generate, iterate, or update an app icon.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# App Icon Generator

Generate an app icon programmatically with a CoreGraphics Swift script, resize it to every required size, and install it into the Xcode asset catalog — with appearance variants (light/dark/tinted).

## Read first — the Liquid Glass era (iOS 26 / macOS 26)

> **Apple icon standards verified as of July 2026** — Icon Composer, Xcode 26, macOS Tahoe 26.4+. This guidance is static (the skill does no per-run web lookup); if that date is well in the past or the OS has moved on, re-verify against the [HIG · App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons) before trusting the specifics below.

Apple's shippable icon format changed. On iOS 26 / macOS 26 the modern app icon is a **layered, light-responsive Liquid Glass icon** authored in **Icon Composer** (free; ships with Xcode 26, needs macOS Tahoe 26.4+). You supply *flat* artwork in up to **four depth groups** (background → foreground); the **system renders the glass** — specular highlights, refraction, translucency, shadows — and masks the rounded-rect shape. One `.icon` file adapts across iPhone, iPad, Mac, and Apple Watch and across **Default / Dark / Mono (tinted)** appearances.

**So this skill does NOT produce the final iOS 26 icon.** Icon Composer is GUI-first; no script can author a true layered `.icon`. Its two honest roles are:

1. **Placeholder** — a fast flat 1024 PNG so early builds, TestFlight, and screenshots feel real before you invest in the real icon.
2. **Layered source art** — flat background / midground / foreground PNGs (or SVGs), effect-free, ready to drag into Icon Composer, where you assemble depth and export the `.icon`.

**What changed vs. the classic flow:**
- **Do not bake in lighting.** No pre-painted specular highlights, drop shadows, or gradients-used-as-lighting — the system owns those now, and baking them in double-exposes against the system glass. (The `drawShine`/`drawShadow` blocks below are **legacy-only**, off by default for iOS 26+ targets.)
- **Do not round the corners.** Icon Composer / the system apply the shape mask — fill a full square canvas.
- **SVG for shapes, PNG for effects** — vector where you can, raster only where you must.
- **Provide appearance variants** — light (default), dark, and tinted/mono. A single flat PNG only fills the light slot and won't adapt on iOS 18+.

**Detect the target first:** read the deployment target (`IPHONEOS_DEPLOYMENT_TARGET` / `MACOSX_DEPLOYMENT_TARGET` in the pbxproj, or `.planning/APP.md`). iOS 26+ / macOS 26+ → lead with the Icon Composer handoff and treat the flat PNG as a placeholder. Older targets → the classic flat + appearances path is fine to ship. **If the deployment target is newer than the "verified as of" date above, flag it to the user and re-verify the icon rules against the current HIG before generating** — the skill won't know about anything Apple shipped after that date.

## When This Skill Activates

Use this skill when the user:
- Asks to "generate an app icon" or "create an icon"
- Wants a "placeholder icon" or "app icon design"
- Mentions "icon for my app" or "need an app icon"
- Asks to "update the app icon"

## Pre-Generation Checks

### 1. Project Context Detection

```
Glob: **/Assets.xcassets/AppIcon.appiconset/Contents.json
```

- Identify platform: macOS, iOS, or universal
- Check for existing icon files (warn before overwriting)
- Read `Contents.json` to understand required sizes

### 2. App Context Detection

Gather app information to customize the icon:

```
Read: .planning/APP.md          (if exists — app definition)
Read: .planning/CODEBASE.md     (if exists — app description)
Grep: "CFBundleName" or app name in project files
```

If no planning files exist, ask the user.

## Configuration Questions

Ask via AskUserQuestion:

### Question 1: App Category
"What category best describes your app?"
- **Productivity** — Clean geometric shapes, blues/teals
- **Creative/Media** — Vibrant colors, camera/brush/music motifs
- **Developer Tools** — Dark backgrounds, terminal/code symbols
- **Utilities** — Functional shapes, neutral/system colors

### Question 2: Visual Style
"What visual style do you prefer?"
- **Bold Symbol** — Single prominent shape/icon centered (like the record button)
- **Contained Scene** — A scene inside a shape (like a monitor with elements)
- **Abstract Mark** — Geometric/abstract design (like viewfinder brackets)
- **Gradient Glyph** — SF Symbol-style glyph on gradient background

### Question 3: Color Palette
"What color palette fits your app?"
- **Deep Blue/Indigo** — Professional, trustworthy (navy #0f0c29 to indigo #302b63)
- **Teal/Cyan** — Fresh, modern (dark teal #0a1628 to blue #1a4a6b)
- **Purple/Violet** — Creative, premium (midnight #1a0533 to violet #4a1a8a)
- **Warm/Orange** — Energetic, friendly (dark red #2d1117 to orange #c0392b)

### Question 4: Accent Color
"What accent color for the focal element?"
- **Red** — Attention, recording, alerts (#ff453a to #d63031)
- **Blue** — Trust, communication (#007aff to #0056b3)
- **Green** — Success, nature, health (#34c759 to #248a3d)
- **Gold/Yellow** — Premium, energy (#ffd60a to #c7a600)

## Apple HIG Icon Guidelines

**Read `apple-hig-icons.md` before generating.**

**Timeless rules (all eras):**

1. **No text** in the icon — must be universally recognizable
2. **Single focal point** — one clear element the eye is drawn to
3. **Simple shapes** — legible at 16×16 (macOS menu bar) and at Home-screen size
4. **Fill a full square canvas** — never bake in rounded corners; the system / Icon Composer apply the shape mask
5. **Front-facing** — no 3D tilts or dramatic angles
6. **Ensure contrast** — the focal element must stand out from the background
7. **Platform-appropriate detail** — macOS can be more detailed (displays larger); iOS simpler

**Liquid Glass era rules (iOS 26 / macOS 26):**

8. **The system owns lighting.** No baked specular, drop shadows, or gradients-as-lighting — Icon Composer / the system add depth, refraction, and highlights. Keep artwork flat.
9. **Provide appearance variants** — light (default), dark, and tinted/mono. Make sure the mark reads on all three (tinted renders as a monochrome silhouette on a system-tinted background).
10. **Layer, don't flatten (final icon)** — organize art into ≤4 depth groups for Icon Composer; SVG for shapes, PNG only for texture.

## Generation Process

### Step 1: Determine Icon Design

Based on the user's answers (or app context), select:
- **Background**: Gradient direction, colors, optional radial glow
- **Primary Element**: The main shape/symbol
- **Secondary Elements**: Optional ring, glow, accent shapes
- **Style Modifiers**: stroke weight (⚠️ skip Shine/shadow for iOS 26+ targets — the system applies Liquid Glass specular and shadow; baking them in double-exposes)

### Step 2: Generate Swift Script

Create a self-contained Swift script at `scripts/generate-icon.swift` that:
- Uses `import AppKit` and `CoreGraphics` (no dependencies)
- Generates **3 variants** at 1024x1024
- Saves to `icon-variants/` directory
- Uses the design parameters from Step 1

**Script structure:**
```swift
#!/usr/bin/env swift
import AppKit
import CoreGraphics

let size: CGFloat = 1024
// ... helper functions (gradients, glows, shapes)
// ... variant generation functions
// ... save and output
```

**Design building blocks** (combine these based on category/style):

| Building Block | Function | Use For |
|---------------|----------|---------|
| `drawGradientBackground` | Linear gradient fill | All icons |
| `drawRadialGlow` | Soft colored glow behind focal element | Adding depth |
| `drawCircle` | Filled/stroked circle | Record buttons, dots, orbs |
| `drawRoundedRect` | Rounded rectangle | Screens, cards, containers |
| `drawRing` | Circle outline | Borders, focus rings |
| `drawBrackets` | Corner bracket marks | Viewfinders, capture |
| `drawMonitor` | Screen + stand shape | Screen/display apps |
| `drawShield` | Shield outline | Security/privacy apps |
| `drawGear` | Gear/cog shape | Settings/utility apps |
| `drawWaveform` | Audio waveform bars | Audio/music apps |
| `drawDocument` | Page with fold corner | Document/writing apps |
| `drawShine` | Elliptical specular highlight | ⚠️ Legacy only — off for iOS 26+ (system paints its own specular) |
| `drawShadow` | Drop shadow beneath element | ⚠️ Legacy only — off for iOS 26+ (system casts its own shadow) |

### Step 3: Run Script and Present Variants

```bash
swift scripts/generate-icon.swift
```

Show all 3 variants to the user using the Read tool (Claude can view images).
Ask the user to pick one, or request adjustments.

### Step 4: Resize and Install

Once the user picks a variant:

1. **Resize** using `sips` (built into macOS):

For **macOS** (10 sizes):
```bash
sips -z 16 16     master.png --out icon_16x16.png
sips -z 32 32     master.png --out icon_16x16@2x.png
sips -z 32 32     master.png --out icon_32x32.png
sips -z 64 64     master.png --out icon_32x32@2x.png
sips -z 128 128   master.png --out icon_128x128.png
sips -z 256 256   master.png --out icon_128x128@2x.png
sips -z 256 256   master.png --out icon_256x256.png
sips -z 512 512   master.png --out icon_256x256@2x.png
sips -z 512 512   master.png --out icon_512x512.png
sips -z 1024 1024 master.png --out icon_512x512@2x.png
```

For **iOS** (single 1024x1024):
```bash
cp master.png icon_1024x1024.png
```

2. **Write Contents.json** for the asset catalog

For **macOS**:
```json
{
  "images": [
    { "filename": "icon_16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16" },
    { "filename": "icon_16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16" },
    { "filename": "icon_32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32" },
    { "filename": "icon_32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32" },
    { "filename": "icon_128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128" },
    { "filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128" },
    { "filename": "icon_256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256" },
    { "filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256" },
    { "filename": "icon_512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512" },
    { "filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

For **iOS** (single size, system generates others):
```json
{
  "images": [
    { "filename": "icon_1024x1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

3. **Copy files** into the asset catalog directory
4. **Build** to verify: `xcodebuild build -scheme <scheme> -destination 'platform=<platform>' -quiet`

### Step 4.5: Appearance variants & Icon Composer handoff

**Appearance variants (iOS 18+, scriptable).** For the flat path, generate three 1024 PNGs — light (default), dark, and a monochrome/tinted mark — and declare them so the icon adapts to the user's Home screen:

```json
{
  "images": [
    { "filename": "icon_light.png",  "idiom": "universal", "platform": "ios", "size": "1024x1024" },
    { "filename": "icon_dark.png",   "idiom": "universal", "platform": "ios", "size": "1024x1024",
      "appearances": [ { "appearance": "luminosity", "value": "dark" } ] },
    { "filename": "icon_tinted.png", "idiom": "universal", "platform": "ios", "size": "1024x1024",
      "appearances": [ { "appearance": "luminosity", "value": "tinted" } ] }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

**Icon Composer handoff (iOS 26+ / the shippable icon).** The flat PNGs above are a placeholder. For the real Liquid Glass icon:

1. Export the design as **flat layers** — background, midground, foreground — as SVG (shapes) or PNG (texture), with **no** baked highlights, shadows, or corners.
2. Open **Icon Composer** (Xcode 26 ▸ Open Developer Tool ▸ Icon Composer; needs macOS Tahoe 26.4+). Drag the layers in, organize into ≤4 depth groups, tune specular / refraction / translucency / shadow (don't overdo refraction), and check the Default / Dark / Mono previews.
3. **Export `.icon`** and add it to the target (it replaces the `AppIcon` set). Icon Composer also exports a flattened 1024 PNG for App Store marketing.

This is a manual GUI step by design — the skill prepares the layers and hands off; it does not author the `.icon`.

### Step 4.6: Validate Before Install (hard checks — do not skip)

An icon that "looks fine" as a 1024px file on a neutral canvas can still fail on a real Home Screen. All three checks below caught real shipped bugs:

1. **Adjacent-element contrast.** Any mark element that touches the icon *background* (a header band, badge ring, tab, outline) must clearly contrast with that background — same-hue-slightly-darker vanishes at Home Screen size, amputating part of the mark. Elements sitting on the card/mark interior only need contrast against the card.
2. **Judge at 60–64 px, not 1024.** `sips -Z 120` each variant and Read the small render — that's the size users see. Subtle contrast that survives at 1024 dies at 60.
3. **Tinted variant must be strictly grayscale.** iOS 18+ overlays the user's tint on the tinted variant; baked-in color renders wrong. Beware colors hardcoded *inside* shared draw functions — the tinted call site can pass gray arguments while the function paints brand color anyway. Parametrize every color per variant, then verify the exported PNG has zero saturation (e.g. a quick pixel scan).
4. **See it in place (required, not optional).** Build to a simulator and screenshot the Home Screen — the icon among other apps on a real wallpaper is the only honest review. Check light, dark, and tinted appearances.

### Step 5: Cleanup

- Keep `scripts/generate-icon.swift` for future regeneration
- Remove `icon-variants/` directory (or add to `.gitignore`)

## Category-Specific Design Recipes

### Productivity Apps
- **Background**: Deep blue (#0f1b3d) to teal (#1a4a6b)
- **Element**: Checkmark, list, or document shape in white
- **Accent**: Green checkmark or blue highlight
- **Style**: Clean, minimal, professional

### Creative/Media Apps
- **Background**: Dark purple (#1a0533) to magenta (#6b1a5c)
- **Element**: Camera lens, brush stroke, play button, or waveform
- **Accent**: Red record dot, orange/yellow creative spark
- **Style**: Vibrant, expressive

### Developer Tools
- **Background**: Near-black (#0d1117) to dark gray (#1a1a2e)
- **Element**: Terminal bracket `>_`, code braces `{}`, or gear
- **Accent**: Green (#34c759) or cyan (#00d4ff) terminal glow
- **Style**: Monospace feel, technical

### Communication Apps
- **Background**: Blue (#0a2463) to lighter blue (#1e5aa8)
- **Element**: Speech bubble, person silhouette, or connection lines
- **Accent**: White or light blue
- **Style**: Friendly, approachable

### Utility Apps
- **Background**: Dark gray (#1a1a2e) to medium gray (#2d2d44)
- **Element**: Gear, wrench, shield, or lightning bolt
- **Accent**: System blue (#007aff) or orange (#ff9500)
- **Style**: Functional, trustworthy

### Finance Apps
- **Background**: Dark green (#0a2e1a) to emerald (#1a6b3a)
- **Element**: Chart line, coin, or dollar symbol
- **Accent**: Gold (#ffd60a) or green (#34c759)
- **Style**: Secure, premium

### Health/Fitness Apps
- **Background**: Dark red (#2d1117) to pink (#6b1a3a)
- **Element**: Heart, activity ring, or pulse line
- **Accent**: Red (#ff3b30) or green (#34c759)
- **Style**: Energetic, motivating

### Education Apps
- **Background**: Deep blue (#0f0c29) to royal blue (#302b63)
- **Element**: Book, graduation cap, or lightbulb
- **Accent**: Yellow (#ffd60a) or white
- **Style**: Inspiring, trustworthy

## Output Summary

After completion, report:

```
Icon installed!

Type:     [placeholder flat icon | classic icon + appearances]
Master:   scripts/generate-icon.swift (re-run to regenerate)
Sizes:    [list] · appearances: [light/dark/tinted]
Location: [path to AppIcon.appiconset]

⚠️ For an iOS 26+ / macOS 26+ target this is a PLACEHOLDER. Finish the real
   Liquid Glass icon in Icon Composer (see the handoff step) before submitting.

Build and run to see it: Home screen (iOS) · menu bar / Finder / Spotlight (macOS).
```

## Iteration

If the user wants changes:
1. Modify the Swift script parameters (colors, shapes, sizes)
2. Re-run: `swift scripts/generate-icon.swift`
3. Show the updated variants
4. Resize and reinstall once approved

Common adjustment requests:
- "Make the record dot bigger/smaller" → adjust radius parameter
- "Different background color" → change gradient hex values
- "Add more depth" → add a radial glow (⚠️ not baked shine on iOS 26+ — add depth in Icon Composer instead)
- "Too busy, simplify" → remove secondary elements
- "Doesn't look good at small size" → increase stroke widths, simplify shapes
