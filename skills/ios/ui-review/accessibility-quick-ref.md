# Accessibility Quick Reference

Quick reference for SwiftUI accessibility implementation.

## Essential Modifiers

### Labels & Descriptions
```swift
// Label: What the element is
.accessibilityLabel("Add new expense")

// Value: Current state/value
.accessibilityValue("$150.00")

// Hint: What happens when activated
.accessibilityHint("Creates a new expense in this group")
```

### Traits
```swift
// Add traits
.accessibilityAddTraits(.isButton)
.accessibilityAddTraits(.isHeader)
.accessibilityAddTraits(.isSelected)
.accessibilityAddTraits(.updatesFrequently)

// Remove traits
.accessibilityRemoveTraits(.isImage)
```

### Grouping & Hiding
```swift
// Combine multiple elements into one
VStack {
    Text("Total")
    Text("$150")
}
.accessibilityElement(children: .combine)

// Hide decorative elements
Image("background-pattern")
    .accessibilityHidden(true)
```

### Custom Actions
```swift
.accessibilityAction(named: "Delete") {
    deleteExpense()
}

.accessibilityAction(named: "Edit") {
    showEditSheet()
}
```

## Common Patterns

### Icon-Only Buttons
```swift
// ❌ Bad
Button {
    addExpense()
} label: {
    Image(systemName: "plus")
}

// ✅ Good
Button {
    addExpense()
} label: {
    Image(systemName: "plus")
}
.accessibilityLabel("Add expense")
```

### Custom Controls
```swift
// ❌ Bad - VoiceOver doesn't know it's tappable
Image(systemName: "star")
    .onTapGesture { toggleFavorite() }

// ✅ Good
Image(systemName: "star")
    .onTapGesture { toggleFavorite() }
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel("Favorite")
    .accessibilityValue(isFavorite ? "On" : "Off")
```

### Lists with Actions
```swift
List {
    ForEach(expenses) { expense in
        ExpenseRow(expense: expense)
            .accessibilityAction(named: "Delete") {
                delete(expense)
            }
            .accessibilityAction(named: "Edit") {
                edit(expense)
            }
    }
}
```

### Toggle States
```swift
Toggle("Enable notifications", isOn: $notificationsEnabled)
    .accessibilityValue(notificationsEnabled ? "Enabled" : "Disabled")
```

### Progress & Status
```swift
ProgressView("Loading expenses", value: progress, total: 1.0)
    .accessibilityLabel("Loading")
    .accessibilityValue("\(Int(progress * 100)) percent complete")
```

## Dynamic Type Support

### Use Semantic Text Styles
```swift
// ✅ Good - Scales automatically
Text("Expense Title")
    .font(.headline)

Text("Description")
    .font(.body)

Text("Date")
    .font(.caption)

// ❌ Bad - Fixed size
Text("Expense Title")
    .font(.system(size: 18))
```

### Custom Fonts with Scaling
```swift
// ✅ Good - Custom font that scales
Text("Title")
    .font(.custom("SF Pro Display", size: 17, relativeTo: .body))

// ❌ Bad - Fixed custom font
Text("Title")
    .font(.custom("SF Pro Display", fixedSize: 17))
```

### Handle Large Text
```swift
// Use ViewThatFits for flexibility
ViewThatFits {
    HStack {
        Text("Long text here")
        Spacer()
        Text("$150")
    }

    VStack(alignment: .leading) {
        Text("Long text here")
        Text("$150")
    }
}

// Or use dynamic layout
@Environment(\.sizeCategory) var sizeCategory

var body: some View {
    if sizeCategory.isAccessibilityCategory {
        VStack { /* Vertical layout */ }
    } else {
        HStack { /* Horizontal layout */ }
    }
}
```

## Color & Contrast

### Semantic Colors
```swift
// ✅ Good - Adapts to light/dark mode
Text("Title")
    .foregroundColor(.primary)

Background()
    .fill(Color(.systemBackground))

// ❌ Bad - Fixed colors
Text("Title")
    .foregroundColor(.black)

Background()
    .fill(Color.white)
```

### Contrast Requirements
- **Normal text**: 4.5:1 contrast ratio
- **Large text** (18pt+): 3:1 contrast ratio
- **UI components**: 3:1 contrast ratio

Use Xcode's Accessibility Inspector to verify.

## Testing Checklist

### VoiceOver Testing
- [ ] All interactive elements have labels
- [ ] Navigation order is logical
- [ ] Custom actions work correctly
- [ ] Dynamic content is announced

### Dynamic Type Testing
- [ ] Test at largest size (Accessibility XXXL)
- [ ] No clipped text
- [ ] Layouts adapt appropriately
- [ ] Buttons remain tappable

### Visual Testing
- [ ] Test in Dark Mode
- [ ] Test with Increased Contrast
- [ ] Test with Reduce Transparency
- [ ] Test with Reduce Motion

### Keyboard Testing (iPad/Mac)
- [ ] All actions have keyboard shortcuts
- [ ] Focus indicator is visible
- [ ] Tab order is logical

## Testing in Simulator

### Enable Accessibility Features
```
Settings → Accessibility → VoiceOver → On
Settings → Accessibility → Display & Text Size → Larger Text
Settings → Accessibility → Display & Text Size → Increase Contrast
Settings → Accessibility → Motion → Reduce Motion
```

### Xcode Accessibility Inspector
```
Xcode → Open Developer Tool → Accessibility Inspector
```

Features:
- Inspect element accessibility properties
- Audit for common issues
- Check color contrast
- Test with different settings

## Resources

- [Apple Accessibility Documentation](https://developer.apple.com/documentation/accessibility)
- [SwiftUI Accessibility Modifiers](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
