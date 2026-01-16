# Accessibility Generator

Generate accessibility infrastructure for VoiceOver, Dynamic Type, and accessibility features.

## When to Use

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
