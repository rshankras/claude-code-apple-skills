---
name: accessibility-generator
description: Generate accessibility infrastructure for VoiceOver, Dynamic Type, and accessibility features. Use when improving app accessibility, adding accessibility labels and hints, or auditing compliance.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Accessibility Generator

Generate accessibility infrastructure for VoiceOver, Dynamic Type, and accessibility features.

## When This Skill Activates

- User wants to improve app accessibility
- User mentions VoiceOver, Dynamic Type, or accessibility
- User needs to add accessibility labels and hints
- User wants to audit accessibility compliance

## Pre-Generation Checks

```bash
# Check existing accessibility usage
grep -r "accessibilityLabel\|accessibilityHint\|AccessibilityFocused" --include="*.swift" | head -5
```

## Key Features

### Accessibility Labels

```swift
Image(systemName: "heart.fill")
    .accessibilityLabel("Favorite")
    .accessibilityHint("Double tap to remove from favorites")
```

### Dynamic Type Support

```swift
Text("Title")
    .font(.title)  // Scales automatically
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)  // Limit max size
```

### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

withAnimation(reduceMotion ? nil : .spring()) {
    // Animation
}
```

### VoiceOver Groups

```swift
VStack {
    Text("Item Name")
    Text("$9.99")
}
.accessibilityElement(children: .combine)
```

## Visual Accessibility: Numbers and APIs (WWDC20)

| Setting | Threshold / API | What to do |
|---------|-----------------|------------|
| Contrast | **4.5:1 minimum** ("generally the lowest acceptable ratio"); ~**7.5:1** for comfort on dark backgrounds | Check text and glyphs against their actual backgrounds |
| Differentiate Without Color | `UIAccessibility.shouldDifferentiateWithoutColor` | Add shapes/symbols wherever color is the only signal (red/green states) |
| Button Shapes | `UIAccessibility.buttonShapesEnabled` + its change notification | Show borders/underlines on plain-text buttons when on |
| Increase Contrast | System colors adapt for free; custom colors need a **"High Contrast" variant in the asset catalog** | Never ship a single hex for both modes |
| Dynamic Type | `preferredContentSizeCategory` | **Never truncate** — set line count to 0 so text wraps; reflow layout at accessibility sizes |
| Bold Text | `UIAccessibility.isBoldTextEnabled` | Free with system text styles; custom fonts must swap weights manually |
| Reduce Motion | `isReduceMotionEnabled`, `prefersCrossFadeTransitions` | Gate animations, parallax, and video autoplay; prefer cross-fades over sliding transitions |
| Smart Invert | `.accessibilityIgnoresInvertColors()` | Apply to photos, videos, and full-color icons so they don't invert |
| Reduce Transparency | `UIAccessibility.isReduceTransparencyEnabled` | Render blur/vibrancy backgrounds as opaque |

SwiftUI mirrors most of these as environment values (`\.accessibilityReduceMotion` above, plus `\.accessibilityDifferentiateWithoutColor`, `\.legibilityWeight`, `\.accessibilityReduceTransparency`).

## Inclusive Design Principles (WWDC25)

- **About 1 in 7 people has a disability** — accessibility features are mainstream features.
- Provide information through **multiple senses**: captions for audio, audible/haptic paths for visual cues.
- Support **multiple input methods** — touch, keyboard, voice, switch — for every action.
- **Larger Text scales text up to ~3x** — layouts must reflow, not clip or overlap.
- Inclusion is **iterative, not one-time** — re-audit each release, not just before launch.

## Generated Files

```
Sources/Accessibility/
├── AccessibilityModifiers.swift   # Custom view modifiers
├── AccessibilityHelpers.swift     # Label builders
└── AccessibilityStrings.swift     # Localized labels
```

## Audit Checklist

- [ ] All interactive elements have labels
- [ ] Images have descriptions or are hidden decoratively
- [ ] Color is not the only indicator
- [ ] Touch targets are at least 44×44 points
- [ ] Dynamic Type is supported
- [ ] Reduce Motion is respected
- [ ] VoiceOver order is logical

## References

- [Accessibility in SwiftUI](https://developer.apple.com/documentation/swiftui/accessibility)
- [Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
