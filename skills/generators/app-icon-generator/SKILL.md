---
name: app-icon-generator
description: Generates app icons programmatically using CoreGraphics following Apple HIG. Use when user wants to create, generate, or design an app icon for macOS or iOS.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# App Icon Generator

Generate production-quality app icons programmatically using a CoreGraphics Swift script. Produces all required sizes and installs into the Xcode asset catalog.

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

**Read `apple-hig-icons.md` before generating.** Key rules:

1. **No text** in the icon — must be universally recognizable
2. **Single focal point** — one clear element the eye is drawn to
3. **Simple shapes** — must be legible at 16x16 (macOS menu bar)
4. **Fill the canvas** — macOS/iOS apply the rounded rect mask automatically
5. **Front-facing perspective** — no 3D tilts or dramatic angles
6. **Use gradients sparingly** — subtle depth, not rainbow
7. **Ensure contrast** — the focal element must stand out from background
8. **Platform-appropriate**:
   - macOS: Can be more detailed (icons display larger)
   - iOS: Keep simpler (smaller grid, more rounded)

## Generation Process

### Step 1: Determine Icon Design

Based on the user's answers (or app context), select:
- **Background**: Gradient direction, colors, optional radial glow
- **Primary Element**: The main shape/symbol
- **Secondary Elements**: Optional ring, glow, accent shapes
- **Style Modifiers**: Shine, shadow, stroke weight

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
| `drawShine` | Elliptical specular highlight | Adding polish |
| `drawShadow` | Drop shadow beneath element | Adding depth |

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
Icon installed successfully!

Master: scripts/generate-icon.swift (re-run to regenerate)
Sizes:  [list of sizes generated]
Location: [path to AppIcon.appiconset]

Build and run to see the icon in:
- Menu bar (macOS)
- Home screen (iOS)
- Finder / Spotlight
- About view
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
- "Add more depth" → add radial glow or shine
- "Too busy, simplify" → remove secondary elements
- "Doesn't look good at small size" → increase stroke widths, simplify shapes
