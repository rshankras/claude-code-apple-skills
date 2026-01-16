# Accessibility Patterns

Best practices for building accessible iOS/macOS apps.

## VoiceOver

### Labels and Hints

```swift
Button(action: { deleteItem() }) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")
.accessibilityHint("Removes this item permanently")
```

### Grouping Elements

```swift
// Combine related elements into one
HStack {
    Image(systemName: "star.fill")
    Text("4.5 rating")
}
.accessibilityElement(children: .combine)

// Custom combined label
VStack {
    Text(item.name)
    Text(item.price)
}
.accessibilityElement(children: .ignore)
.accessibilityLabel("\(item.name), \(item.price)")
```

### Custom Actions

```swift
struct ItemRow: View {
    let item: Item

    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            Button("Edit") { editItem() }
            Button("Delete") { deleteItem() }
            Button("Share") { shareItem() }
        }
    }
}
```

### Traits

```swift
Text("Welcome")
    .accessibilityAddTraits(.isHeader)

Button("Submit") { }
    .accessibilityAddTraits(.startsMediaSession)

Text("Status: Active")
    .accessibilityAddTraits(.updatesFrequently)
```

### Focus Management

```swift
struct FormView: View {
    @AccessibilityFocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, email, submit
    }

    var body: some View {
        VStack {
            TextField("Name", text: $name)
                .accessibilityFocused($focusedField, equals: .name)

            TextField("Email", text: $email)
                .accessibilityFocused($focusedField, equals: .email)

            Button("Submit") { submit() }
                .accessibilityFocused($focusedField, equals: .submit)
        }
        .onAppear {
            focusedField = .name
        }
    }
}
```

## Dynamic Type

### Automatic Scaling

```swift
// Prefer semantic fonts - they scale automatically
Text("Title").font(.title)
Text("Body").font(.body)
Text("Caption").font(.caption)

// Custom fonts with scaling
Text("Custom")
    .font(.custom("Helvetica", size: 16, relativeTo: .body))
```

### Limiting Scale

```swift
Text("Fixed Range")
    .dynamicTypeSize(.small ... .xxxLarge)

Text("No Accessibility Sizes")
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

### Adjusting Layouts

```swift
@Environment(\.dynamicTypeSize) private var typeSize

var body: some View {
    if typeSize >= .accessibility1 {
        // Vertical layout for large text
        VStack(alignment: .leading) {
            label
            value
        }
    } else {
        // Horizontal layout for normal text
        HStack {
            label
            Spacer()
            value
        }
    }
}
```

### ScaledMetric

```swift
@ScaledMetric(relativeTo: .body) private var iconSize = 24.0
@ScaledMetric private var spacing = 8.0

Image(systemName: "star")
    .frame(width: iconSize, height: iconSize)
    .padding(spacing)
```

## Motion and Animation

### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

func toggleExpanded() {
    if reduceMotion {
        isExpanded.toggle()  // Instant
    } else {
        withAnimation(.spring()) {
            isExpanded.toggle()
        }
    }
}
```

### Safe Animations

```swift
extension Animation {
    static var accessibleSpring: Animation {
        @Environment(\.accessibilityReduceMotion) var reduceMotion
        return reduceMotion ? .none : .spring()
    }
}

// View modifier
struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: UUID())
    }
}
```

## Color and Contrast

### Reduce Transparency

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency

var backgroundMaterial: some ShapeStyle {
    reduceTransparency ? Color.systemBackground : Material.regular
}
```

### High Contrast Colors

```swift
@Environment(\.colorSchemeContrast) private var contrast

var textColor: Color {
    contrast == .increased ? .primary : .secondary
}
```

### Color Blind Support

```swift
// Don't rely on color alone
HStack {
    Circle()
        .fill(status.color)
        .frame(width: 8, height: 8)
    Text(status.label)  // Always include text
}

// Use patterns or shapes
if isError {
    Image(systemName: "exclamationmark.triangle")  // Shape indicates error
        .foregroundStyle(.red)
}
```

## Accessibility Modifiers

### Custom Modifier

```swift
extension View {
    func accessibleCard(title: String, description: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityHint(description)
            .accessibilityAddTraits(.isButton)
    }

    func accessibleImage(_ description: String) -> some View {
        self
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }

    func accessibleDecorative() -> some View {
        self.accessibilityHidden(true)
    }
}
```

### Usage

```swift
CardView(item: item)
    .accessibleCard(
        title: item.name,
        description: "Double tap to view details"
    )

Image("hero")
    .accessibleImage("Sunset over mountains")

Image("decorative-line")
    .accessibleDecorative()
```

## Testing Accessibility

### Accessibility Inspector

1. Xcode > Open Developer Tool > Accessibility Inspector
2. Target your simulator/device
3. Navigate through UI elements
4. Check labels, hints, traits

### Unit Testing

```swift
import XCTest
@testable import YourApp

final class AccessibilityTests: XCTestCase {

    func testButtonHasLabel() {
        let button = MyButton()
        let view = button.body

        // Use accessibility audit APIs
        XCTAssertNotNil(view.accessibilityLabel)
    }
}
```

### UI Testing

```swift
func testVoiceOverNavigation() {
    let app = XCUIApplication()
    app.launch()

    // Check element exists and is accessible
    let button = app.buttons["Add Item"]
    XCTAssertTrue(button.exists)
    XCTAssertTrue(button.isHittable)

    // Check accessibility label
    XCTAssertEqual(button.label, "Add Item")
}
```

## Localized Accessibility

```swift
enum A11y {
    static let addButton = String(localized: "accessibility.add_button",
                                   defaultValue: "Add new item")
    static let deleteHint = String(localized: "accessibility.delete_hint",
                                    defaultValue: "Double tap to delete")

    static func itemCount(_ count: Int) -> String {
        String(localized: "accessibility.item_count \(count)",
               defaultValue: "\(count) items")
    }
}

// Usage
Button(action: { }) {
    Image(systemName: "plus")
}
.accessibilityLabel(A11y.addButton)
```

## Checklist

### Visual
- [ ] Text uses semantic fonts (`.body`, `.title`, etc.)
- [ ] Custom fonts use `relativeTo:` for scaling
- [ ] Minimum touch target 44×44 points
- [ ] Color is not the only indicator
- [ ] Sufficient color contrast (4.5:1 for text)

### VoiceOver
- [ ] All interactive elements have labels
- [ ] Decorative images are hidden
- [ ] Meaningful images have descriptions
- [ ] Custom controls have appropriate traits
- [ ] Related content is grouped

### Motion
- [ ] Animations respect Reduce Motion
- [ ] No auto-playing videos without control
- [ ] Flashing content is avoided

### Interaction
- [ ] Full keyboard navigation support
- [ ] Focus order is logical
- [ ] Error states are announced
