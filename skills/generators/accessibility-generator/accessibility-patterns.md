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

### Writing Great Labels (WWDC19 254)

A label is a localized string that succinctly identifies the element — "the difference
between someone using and loving your app or someone deleting your app" (WWDC19 254).

- **Never include the control type** — VoiceOver appends the trait itself:

```swift
// ❌ VoiceOver speaks "Add button, button"
addButton.accessibilityLabel = "Add button"

// ✅ VoiceOver speaks "Add, button"
addButton.accessibilityLabel = "Add"
```

- **Add context only when the screen doesn't provide it** — the WWDC19 254 ladder for one
  plus button: bare "Plus" (ambiguous) → "Add" (nav bar, or a notes app where adding is
  obvious) → "Add to Cart" (shopping app — distinguishes from "Add to Favorites") →
  "Add peanut butter to cart" (a row of products where every add button would otherwise
  read identically):

```swift
// ❌ three identical rows: "Add, button" ×3 — which product?
row.addButton.accessibilityLabel = "Add"

// ✅ per-item context
row.addButton.accessibilityLabel = "Add \(product.name) to cart"
```

- **Skip context the screen already implies** — in a music player, "Play" beats "Play song"
  and "Next" beats "Next song" (WWDC19 254).
- **Succinct beats descriptive**: ✅ "Delete" ❌ "Delete items from the current folder and
  add it to the trash".
- **Update the label when state changes** — a button that toggles add/delete must switch
  "Add" ↔ "Delete" or VoiceOver announces stale state.
- **Label meaningful animations** — give loading spinners `accessibilityLabel = "Loading"`
  so progress is announced (WWDC19 254).
- **Labels are user-facing strings — localize them** like any other copy.

### Conditional and Composed Labels (WWDC24 10073)

Accessibility modifiers take an `isEnabled:` parameter (iOS 18/macOS 15) — when false the
modifier simply doesn't apply, killing the branch-around-views pattern:

```swift
Button(action: favorite) {
    Image(systemName: isSuperFavorite ? "sparkles" : "star.fill")
}
.accessibilityLabel("Super Favorite", isEnabled: isSuperFavorite)
```

The label view-builder passes the existing label into the closure — re-emit it or the
original label is silently dropped (WWDC24 10073):

```swift
TripView(trip: trip)
    .accessibilityLabel { label in
        if let rating = trip.rating { Text(rating) }
        label   // ✅ always re-emit the original label
    }
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

Why custom actions matter (WWDC19 250): they cut **clutter** — a 10-row list with 3
accessory buttons per cell is 30 extra swipe stops before row 10 — and **speed** —
converting a long-press action sheet to a custom action took a Switch Control flow from
18 switch taps to 6 (67% fewer). One set of actions is honored by VoiceOver, Switch
Control (first page of its menu), Full Keyboard Access (Tab-Z), and Voice Control.

Pairing rule (WWDC19 250): when accessory buttons become custom actions, hide the buttons
you replaced — `isAccessibilityElement = false` in UIKit, `.accessibilityHidden(true)` in
SwiftUI — so the same action isn't exposed twice. Keep names short, localized verb phrases
("Toggle favorite", "Send to friend").

Hover-only content (macOS / iPadOS pointer) is unreachable for assistive tech — expose it
through the `accessibilityActions {}` view builder (WWDC24 10073):

```swift
TripView(trip: trip)
    .onHover { showAttachments = $0 }
    .overlay {
        MessageAttachments(attachments: trip.attachments)
            .opacity(showAttachments ? 1 : 0)
    }
    .accessibilityActions {
        MessageAttachments(attachments: trip.attachments)  // exposed as custom actions
    }
```

Widget views can't run closures — pass an App Intent instead:
`.accessibilityAction(named: "Favorite", intent: ToggleRatingIntent(beach: beach))` and
`.accessibilityAction(.magicTap, intent: ComposeIntent(type: .photo))` (WWDC24 10073).

### Custom Rotors (WWDC20 10116)

Sequential swiping walks every element; a rotor jumps through one category (users twist
two fingers to pick a rotor, then swipe down/up for next/previous). Add one rotor per
category users would visually filter by — stores on a map, warnings buried in a long list.

UIKit — set `accessibilityCustomRotors` on the view that owns the content; the
`itemSearchBlock` returns the next/previous result, or **nil at the first/last item** so
VoiceOver focus stays put (WWDC20 10116):

```swift
func storesRotor() -> UIAccessibilityCustomRotor {
    UIAccessibilityCustomRotor(name: "Stores") { [unowned self] predicate in
        let annotations = self.storeAnnotationViews()   // pre-sorted, e.g. by distance
        let current = predicate.currentItem.targetElement as? MKAnnotationView
        let currentIndex = annotations.firstIndex { $0 == current }
        let targetIndex: Int
        switch predicate.searchDirection {
        case .previous: targetIndex = (currentIndex ?? 1) - 1
        case .next:     targetIndex = (currentIndex ?? -1) + 1
        @unknown default: return nil
        }
        guard annotations.indices.contains(targetIndex) else { return nil }  // boundary
        return UIAccessibilityCustomRotorItemResult(
            targetElement: annotations[targetIndex], targetRange: nil)
    }
}
mapView.accessibilityCustomRotors = [storesRotor()]
```

SwiftUI (iOS 15+, WWDC21 10119) — attach `accessibilityRotor` to an accessibility
**container** (List, LazyVStack, or `.accessibilityElement(children: .contain)`);
entries match elements by ID, so view identity matters:

```swift
VStack {
    ForEach(alerts) { alert in
        AlertCellView(alert: alert)
            .accessibilityElement(children: .combine)
    }
}
.accessibilityElement(children: .contain)
.accessibilityRotor("Warnings") {
    ForEach(alerts) { alert in
        if alert.isWarning {
            AccessibilityRotorEntry(alert.title, id: alert.id)
        }
    }
}
```

When the target view isn't the direct child the ID resolves to, declare
`@Namespace var namespace`, mark the target with
`.accessibilityRotorEntry(id: alert.id, in: namespace)`, and pass `in: namespace` to
`AccessibilityRotorEntry(_:id:in:)` (WWDC21 10119). Text views get range-based rotors:
`.accessibilityRotor("Links", textRanges: note.linkRanges)`.

### Data-Rich Rows: the More Content Rotor (WWDC21 10121)

A data-dense cell read top-to-bottom is cognitive overload; a bare name is an incomplete
app. The Accessibility Custom Content API splits the difference: the element speaks a
short label, announces "more content available", and users pull the remaining fields on
demand via the More Content rotor.

```swift
// ✅ short label + on-demand details (SwiftUI)
VStack { Text(dog.name); DogDetailsView(dog: dog) }
    .accessibilityElement(children: .combine)
    .accessibilityCustomContent("Age", dog.age, importance: .high)  // always spoken on focus
    .accessibilityCustomContent("Weight", dog.weight)               // rotor-only
    .accessibilityCustomContent("Description", dog.description)

// ❌ letting .combine concatenate eight fields into one monster label
```

UIKit: `import Accessibility`, conform to `AXCustomContentProvider`, keep
`accessibilityLabel` to identity fields only, and return `[AXCustomContent]` label/value
pairs in the order VoiceOver should present them. Set `.importance = .high` on the one or
two fields users need on every pass — high-importance content is always spoken on focus
and still appears in the rotor (WWDC21 10121).

### Announcements, Toggle Trait, Zoom, and Direct Touch (WWDC23 10036)

```swift
// Announcements are framework-native in SwiftUI — with interruption priorities
AccessibilityNotification.Announcement("Loading Photos View").post()

var lowPriority: AttributedString {
    var s = AttributedString("Camera Loading")
    s.accessibilitySpeechAnnouncementPriority = .low   // .high interrupts and can't be interrupted;
    return s                                           // .default interrupts but is interruptible;
}                                                      // .low queues until other speech finishes
AccessibilityNotification.Announcement(lowPriority).post()
```

- **Toggle-style buttons**: `.accessibilityAddTraits(.isToggle)` (UIKit:
  `.toggleButton`) so on/off state is announced instead of a bare "button" (WWDC23 10036).
- **Zoomable content**: `.accessibilityZoomAction { action in ... }` switching on
  `action.direction` (`.zoomIn` / `.zoomOut`) — announce the new level after applying it.
  UIKit: add the `.supportsZoom` trait and override `accessibilityZoomIn(at:)` /
  `accessibilityZoomOut(at:)`, returning `true` on success.
- **Direct touch**: `.accessibilityDirectTouch(options: .silentOnTouch)` keeps VoiceOver
  quiet over self-voiced UI (a piano key should play, not speak); `.requiresActivation`
  makes VoiceOver require a double-tap before touches pass through (WWDC23 10036).
- **Element shape**: `.contentShape(.accessibility, Circle())` reshapes the VoiceOver
  cursor and touch-exploration bounds without affecting hit testing or gestures.
- **UIKit block-based setters** (`accessibilityValueBlock`, `accessibilityLabelBlock`, …)
  re-evaluate on every read — no more stale attributes or subclass overrides:

```swift
// ❌ set-once value goes stale when state changes
zoomView.accessibilityValue = isFiltered ? "Filtered" : "Not Filtered"

// ✅ evaluated each time assistive tech reads it
zoomView.accessibilityValueBlock = { [weak self] in
    guard let self else { return nil }
    return isFiltered ? "Filtered" : "Not Filtered"
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

### System Visual Settings: Check + Observe (WWDC20 10020)

Every visual setting follows one template: read the flag at setup, then observe the paired
notification so the UI updates live when the user toggles it in Settings/Control Center.
(Contrast thresholds and per-setting actions live in this skill's SKILL.md table —
4.5:1 minimum for text.)

| Setting | Flag | Change notification |
|---------|------|---------------------|
| Button Shapes | `UIAccessibility.buttonShapesEnabled` | `buttonShapesEnabledStatusDidChangeNotification` |
| Differentiate Without Color | `UIAccessibility.shouldDifferentiateWithoutColor` | `differentiateWithoutColorDidChangeNotification` |
| Bold Text | `UIAccessibility.isBoldTextEnabled` | `boldTextStatusDidChangeNotification` |
| Reduce Motion | `UIAccessibility.isReduceMotionEnabled` | `reduceMotionStatusDidChangeNotification` |
| Prefer Cross-Fade Transitions | `UIAccessibility.prefersCrossFadeTransitions` | `prefersCrossFadeTransitionsStatusDidChange` |
| Reduce Transparency | `UIAccessibility.isReduceTransparencyEnabled` | `reduceTransparencyStatusDidChangeNotification` |

Smart Invert: flag photos, videos, and full-color icons with
`view.accessibilityIgnoresInvertColors = true` (SwiftUI:
`.accessibilityIgnoresInvertColors()`) so they don't invert (WWDC20 10020). Cross-fade
transitions come free with standard UIKit navigation — only custom transition code needs
the `prefersCrossFadeTransitions` check.

## Custom Controls: Purpose, Value, Actions, Feedback (WWDC26 220)

A control's visual form silently communicates four things; a custom control must restate
all four for assistive tech:

1. **Purpose** — `accessibilityLabel`
2. **Value** — `accessibilityValue` (re-spoken whenever it changes)
3. **Actions** — traits + adjustable/custom actions (+ hints)
4. **Feedback** — announce results as the control is used

```swift
// ✅ single-axis, slider-like control (WWDC26 220)
CoffeeSlider(value: coffee)
    .accessibilityElement()
    .accessibilityLabel("Coffee Dispenser")
    .accessibilityValue("\(Int(coffee)) ounces")
    .accessibilityAddTraits(.adjustable)
    .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: increaseCoffeeAmount()
        case .decrement: decreaseCoffeeAmount()
        @unknown default: break
        }
    }

// ❌ bare shape + drag gesture — VoiceOver sees "Button." or nothing adjustable
```

Technique selection (WWDC26 220):

| Control shape | Technique |
|---------------|-----------|
| Single-axis continuous value (slider-like) | `.adjustable` trait + `accessibilityAdjustableAction` |
| Precise continuous adjustment | VoiceOver passthrough (double-tap-and-hold) + tuned `accessibilityActivationPoint` + throttled announcements |
| Multi-dimensional (2D pad, grid) | multiple named custom actions ("Move Up" / "Move Right" / …) — `.adjustable` models only one axis |
| Multiple free-form gestures (pat/tap/pinch) | `.accessibilityDirectTouch([.requiresActivation])`, `.silentOnTouch` if self-voiced — plus custom-action fallbacks |

- Passthrough starts at the control's `accessibilityActivationPoint` (default: center) —
  move it to the semantically right spot, e.g. the current fill level:
  `.accessibilityActivationPoint(UnitPoint(x: 0.5, y: 1 - value))` (WWDC26 220).
- Throttle live feedback: announce only when the value actually changed AND at least
  0.3 seconds have passed since the last announcement — announcing every change is noise.
- Direct touch isn't universally usable — always add custom-action fallbacks so Switch
  Control and Voice Control (which can't perform direct touch) still work (WWDC26 220).
- Alternative for control shapes a system control already models: borrow its
  accessibility wholesale — `accessibilityRepresentation { Slider(value: $value, in: 0...1) { Text(label) } }`
  (WWDC21 10119). SwiftUI Shapes are not accessible by default.

## Switch Control (WWDC20 10019)

Switch users scan a cursor across the screen (auto-advancing on a timer for single-switch
users) — every extra element is a wait, and every mistap costs scan cycles. VoiceOver
correctness comes first: an app that's 100% VoiceOver-accessible likely already works
well for Switch Control (WWDC20 10019).

```swift
// ✅ group + explicit order so scanning is cheap (UIKit)
containerView.accessibilityNavigationStyle = .combined   // container scans as one stop
containerView.accessibilityElements = [levelFourView, levelFiveView, levelSixView]
```

- **No timeouts while Switch Control runs** — check
  `UIAccessibility.isSwitchControlRunning` (plus its status notification) and relax or
  remove countdowns; pairing-code and auth screens are the classic failure (WWDC20 10019).
- **Confirm destructive actions** — mistaps are more frequent; never one-tap
  delete-all or log-out.
- Convert gestures (long-press, double-tap) into `UIAccessibilityCustomAction`s so they
  surface on the first page of the Switch Control menu; set the action's `image`
  (iOS 14) or the menu shows the first letter of the name.
- `accessibilityRespondsToUserInteraction = true` puts tappable-but-"static" elements
  into the scan cursor.
- React to focus itself for reveal-on-tap UI: override
  `accessibilityElementDidBecomeFocused()` / `accessibilityElementDidLoseFocus()` so no
  menu round-trip is needed (WWDC20 10019).

## Full Keyboard Access (WWDC21 10120)

FKA drives the whole device from a keyboard: Tab/Shift-Tab between elements, Space to
activate, Tab-Z for the actions menu (surfaces `accessibilityCustomActions`), Tab-F to
jump to an element by name.

```swift
// ✅ VoiceOver still reads it; FKA + Switch Control skip it
itemView.isAccessibilityElement = true
itemView.accessibilityLabel = itemDescription
itemView.accessibilityRespondsToUserInteraction = false   // info-only element

// ❌ overriding canBecomeFocused to hide it from FKA — that reconfigures the whole
//    UIFocusSystem and breaks plain iPad Tab navigation for non-FKA keyboard users
```

- The FKA cursor visits every accessibility element; if Space does nothing there, focus
  feels broken — mark info-only elements
  `accessibilityRespondsToUserInteraction = false` (WWDC21 10120).
- Image-only controls are unreachable via Tab-F unless you supply the synonyms users
  might type (also spoken names for Voice Control):

```swift
settingsButton.accessibilityUserInputLabels = ["Settings", "Preferences", "Gear"]
```

- The FKA focus ring uses `accessibilityPath` in screen coordinates — for content in
  scroll views, compute it in the getter (`convert(bounds, to: nil)`) instead of
  assigning once, so it stays correct while scrolling.

## Reading Apps and Long-Form Text (WWDC26 219)

Long-form reading is about moving fluidly through text, not between UI elements. System
text views (`UITextView`, `TextEditor`, `Text` + `.textSelection(.enabled)`,
`NSTextView`) give line/word/character navigation and selection for free — prefer them.
For everything else:

- **Paragraphs in separate views** stick the VoiceOver lines rotor at each boundary.
  Chain them: `accessibilityNextTextNavigationElement` /
  `accessibilityPreviousTextNavigationElement` (UIKit, iOS 18); SwiftUI
  `.accessibilityLinkedGroup(id: pageNumber, in: namespace)` (iOS 27); AppKit
  `accessibilitySharedTextUIElements`.
- **Automatic page turns during read-all**: add the `.causesPageTurn` trait to the
  page's last paragraph and implement `accessibilityScroll(_:)`, posting `.pageScrolled`
  with "Page X of Y" so users hear where they landed (WWDC26 219).
- **Selection-coupled actions** ("Save recommendation") belong in the edit rotor: set
  `customAction.category = UIAccessibilityCustomAction.editCategory`.
- **Custom-rendered text** (own layout engine, scanned pages) loses all free text
  accessibility — adopt the full `UITextInput` protocol (`selectionRects(for:)`,
  `text(in:)`, a `tokenizer`, plus `UITextInteraction(for: .nonEditable)` for system
  selection visuals) to restore native-grade navigation and selection, even for text
  inside images (WWDC26 219).

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

For the full audit workflow — automated `performAccessibilityAudit` XCUITests, Inspector
triage, and App Store Accessibility Nutrition Labels — see `ios/accessibility-audit`.

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
- [ ] Labels omit the control type and carry only the context the screen lacks (WWDC19 254)
- [ ] Decorative images are hidden
- [ ] Meaningful images have descriptions
- [ ] Custom controls have appropriate traits
- [ ] Related content is grouped
- [ ] Data-dense rows use short labels + custom content, not concatenated monster labels

### Motion
- [ ] Animations respect Reduce Motion
- [ ] No auto-playing videos without control
- [ ] Flashing content is avoided

### Interaction
- [ ] Full keyboard navigation support
- [ ] Focus order is logical
- [ ] Error states are announced
- [ ] Custom controls expose purpose, value, actions, and feedback (WWDC26 220)
- [ ] No timeouts while Switch Control is running; destructive actions confirmed
