# Apple Human Interface Guidelines — App Icons

Reference for generating HIG-compliant app icons.

## Universal Principles

### Simplicity
- Embrace simplicity. Find a single element that captures the essence of your app.
- Express that element in a unique shape or combination of shapes.
- Add detail carefully — too much makes the icon muddy at small sizes.

### Recognizability
- People should be able to identify your icon at a glance.
- Avoid replicas of Apple hardware or system icons.
- Use a unique silhouette — if you squint, can you tell it apart from other icons?

### Consistency
- Use a single, centered, front-facing perspective.
- No dramatic tilts, 3D rotations, or extreme angles.
- The icon should feel like it belongs on the platform.

### No Text
- Don't include words in your app icon.
- Text is unreadable at small sizes and doesn't localize.
- Exception: Single letters can work if they ARE the brand (like "A" for App Store).

## Platform-Specific Guidelines

### macOS Icons
- **Shape**: Square canvas, system applies rounded rect mask with ~18.75% corner radius
- **Size range**: 16x16 to 512x512@2x (1024x1024)
- **Detail level**: Can be more detailed than iOS — icons display larger in Finder, Dock
- **Visual weight**: Centered in canvas, fill ~80% of the space
- **Background**: Must fill the entire canvas (no transparency — the system mask handles the shape)

Required sizes:
| Size | Scale | Pixels | Context |
|------|-------|--------|---------|
| 16x16 | 1x | 16 | Finder sidebar, Spotlight |
| 16x16 | 2x | 32 | Retina Finder sidebar |
| 32x32 | 1x | 32 | Finder list view |
| 32x32 | 2x | 64 | Retina Finder list view |
| 128x128 | 1x | 128 | Finder icon view |
| 128x128 | 2x | 256 | Retina Finder icon view |
| 256x256 | 1x | 256 | Finder preview |
| 256x256 | 2x | 512 | Retina Finder preview |
| 512x512 | 1x | 512 | App Store (legacy) |
| 512x512 | 2x | 1024 | App Store, Marketing |

### iOS Icons
- **Shape**: Square canvas, system applies continuous rounded rect (squircle) mask
- **Size**: Single 1024x1024 PNG, system auto-generates all sizes
- **Detail level**: Keep simpler than macOS — icons are smaller on screen
- **Background**: Must fill canvas, no transparency, no rounded corners (system does this)
- **No alpha channel**: iOS icons must be opaque

### watchOS Icons
- **Shape**: Circular mask applied by system
- **Size**: 1024x1024 master, system generates circular variants
- **Detail level**: Very simple — icons are tiny on Watch

## Design Techniques

### Backgrounds

**Linear Gradient** (most common):
- Top-to-bottom or diagonal
- Use 2 colors maximum
- Darker at bottom, lighter at top (natural lighting)
- Don't use pure black (#000000) — use very dark colors instead

**Radial Gradient** (for depth):
- Center glow behind the primary element
- Very subtle (10-20% opacity)
- Same hue family as the primary accent

**Solid Color**:
- Works for bold, simple icons
- Use a slightly lighter center for subtle depth

### Primary Elements

**Best practices for the focal shape:**
- Occupy 50-70% of the canvas
- Centered or very slightly above center
- Use filled shapes, not outlines (outlines disappear at small sizes)
- Consistent stroke weights if using lines (minimum 2% of canvas = ~20px at 1024)

**Shape rendering at small sizes:**
- Test at 16x16 and 32x32 — if the shape is unrecognizable, simplify
- Thick strokes (3%+ of canvas) survive downscaling
- Thin details (<1% of canvas) vanish at small sizes
- Round shapes scale better than sharp corners

### Color

**Color count**: 2-4 colors maximum (background gradient + 1-2 accent colors)

**Contrast ratio**: Focal element should have at least 3:1 contrast against background

**System colors** (Apple's palette, good defaults):
| Name | Hex | Use |
|------|-----|-----|
| System Red | #FF3B30 | Alerts, recording, deletion |
| System Orange | #FF9500 | Warnings, energy |
| System Yellow | #FFCC00 | Highlights, favorites |
| System Green | #34C759 | Success, active, health |
| System Blue | #007AFF | Links, primary actions |
| System Indigo | #5856D6 | Premium, creative |
| System Purple | #AF52DE | Creative, unique |
| System Pink | #FF2D55 | Love, social |
| System Teal | #5AC8FA | Information, calm |

### Depth and Polish

**Specular highlight (shine)**:
- Subtle elliptical highlight on the top half of the focal element
- White at 15-25% opacity, fading to transparent
- Suggests a physical, tactile surface

**Drop shadow**:
- Very subtle (5-10% opacity)
- Small offset (1-2% of canvas)
- Only if the element is "floating" above the background

**Outer ring/border**:
- Thin ring around the primary element (1-2% of canvas width)
- White at 15-25% opacity
- Adds definition and structure

**Glow**:
- Radial gradient behind the primary element
- Same hue as the element, 10-20% opacity
- Radius ~2x the element's radius
- Creates a "lit from within" effect

## Anti-Patterns (What NOT to Do)

1. **No photos or screenshots** — they become unrecognizable blobs at small sizes
2. **No text or words** — unreadable at 16x16
3. **No Apple hardware** — violates guidelines and trademark
4. **No transparency** (iOS) — must be fully opaque
5. **No manual rounded corners** — the system applies the mask
6. **No borders that follow the icon shape** — the system mask clips them unevenly
7. **No overly detailed illustrations** — test at 32x32, if it's muddy, simplify
8. **No pure white backgrounds** — blends with light mode UI, use off-white or a color
9. **No pure black backgrounds** — blends with dark mode UI, use very dark color (e.g., #0f0c29)
10. **No busy patterns or textures** — compete with the focal element
