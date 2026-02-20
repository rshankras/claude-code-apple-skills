# Input Methods: Keyboard, Pointer, Pencil, and Focus

Covers keyboard shortcuts, pointer/trackpad interactions, Apple Pencil support via PencilKit, and the SwiftUI focus system.

## Keyboard Shortcuts

### SwiftUI Keyboard Shortcuts

```swift
struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Item", systemImage: "plus") {
                    createNewItem()
                }
                .keyboardShortcut("n", modifiers: .command) // Cmd+N
            }
        }
    }
}
```

### Common Shortcut Patterns

```swift
// Standard shortcuts users expect
Button("Save") { save() }
    .keyboardShortcut("s", modifiers: .command)          // Cmd+S

Button("Delete") { delete() }
    .keyboardShortcut(.delete, modifiers: .command)      // Cmd+Delete

Button("Find") { showSearch() }
    .keyboardShortcut("f", modifiers: .command)          // Cmd+F

Button("Select All") { selectAll() }
    .keyboardShortcut("a", modifiers: .command)          // Cmd+A

Button("Undo") { undo() }
    .keyboardShortcut("z", modifiers: .command)          // Cmd+Z

Button("Redo") { redo() }
    .keyboardShortcut("z", modifiers: [.command, .shift]) // Cmd+Shift+Z

// Default button (Return key) -- used for primary action in forms/dialogs
Button("Submit") { submit() }
    .keyboardShortcut(.defaultAction)                    // Return/Enter

// Cancel button (Escape key)
Button("Cancel") { cancel() }
    .keyboardShortcut(.cancelAction)                     // Escape
```

### Shortcut Discoverability

When the user holds the Command key, iPadOS shows a discoverability overlay listing all available shortcuts. This works automatically for `.keyboardShortcut()` modifiers. Organize shortcuts with sections using menu structure:

```swift
var body: some Scene {
    WindowGroup {
        ContentView()
    }
    .commands {
        CommandGroup(after: .newItem) {
            Button("New Document") { newDocument() }
                .keyboardShortcut("n", modifiers: .command)
            Button("New Folder") { newFolder() }
                .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandMenu("Edit") {
            Button("Find") { find() }
                .keyboardShortcut("f", modifiers: .command)
            Button("Find and Replace") { findReplace() }
                .keyboardShortcut("f", modifiers: [.command, .option])
        }
    }
}
```

### UIKit Keyboard Shortcuts (UIKeyCommand)

```swift
class DocumentViewController: UIViewController {
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(
                title: "Save",
                action: #selector(saveDocument),
                input: "s",
                modifierFlags: .command,
                discoverabilityTitle: "Save Document"
            ),
            UIKeyCommand(
                title: "New",
                action: #selector(newDocument),
                input: "n",
                modifierFlags: .command,
                discoverabilityTitle: "New Document"
            ),
            UIKeyCommand(
                title: "Close",
                action: #selector(closeDocument),
                input: "w",
                modifierFlags: .command,
                discoverabilityTitle: "Close Document"
            )
        ]
    }

    @objc func saveDocument() { /* ... */ }
    @objc func newDocument() { /* ... */ }
    @objc func closeDocument() { /* ... */ }
}
```

### Arrow Key Navigation (UIKit)

```swift
class GridViewController: UIViewController {
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [],
                        action: #selector(moveUp)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [],
                        action: #selector(moveDown)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [],
                        action: #selector(moveLeft)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [],
                        action: #selector(moveRight)),
        ]
    }
}
```

## Pointer Interactions

### SwiftUI Hover Effects

```swift
// Automatic hover effect (highlight)
Button("Action") { performAction() }
    .hoverEffect()           // Default: .automatic

// Specific hover effects
Image(systemName: "star")
    .hoverEffect(.highlight)  // Spotlight-like highlight
    .onTapGesture { toggleFavorite() }

Text("Hoverable Text")
    .hoverEffect(.lift)       // Lifts toward user, adds shadow

// Custom hover region
RoundedRectangle(cornerRadius: 12)
    .fill(Color.blue)
    .hoverEffect(.highlight)
    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 12))
```

### Hover State Detection (SwiftUI)

```swift
struct HoverableCard: View {
    @State private var isHovered = false

    var body: some View {
        VStack {
            Text("Card Content")
        }
        .padding()
        .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
```

### UIKit Pointer Interactions

```swift
class CustomButton: UIButton, UIPointerInteractionDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addInteraction(UIPointerInteraction(delegate: self))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addInteraction(UIPointerInteraction(delegate: self))
    }

    func pointerInteraction(
        _ interaction: UIPointerInteraction,
        styleFor region: UIPointerRegion
    ) -> UIPointerStyle? {
        // Lift effect -- element lifts up with shadow
        let targetedPreview = UITargetedPreview(view: self)
        return UIPointerStyle(effect: .lift(targetedPreview))
    }
}
```

### Custom Pointer Shapes

```swift
func pointerInteraction(
    _ interaction: UIPointerInteraction,
    styleFor region: UIPointerRegion
) -> UIPointerStyle? {
    // Beam shape for text areas
    let shape = UIPointerShape.verticalBeam(length: 20)
    return UIPointerStyle(shape: shape)
}

// Available shapes:
// .defaultPointer     -- standard arrow
// .verticalBeam       -- text cursor (I-beam)
// .horizontalBeam     -- horizontal text cursor
// .roundedRect(frame) -- custom rectangle region
```

### Standard UIKit Controls

Standard UIKit controls (UIButton, UIBarButtonItem, UISegmentedControl, UISlider, UISwitch, UITableViewCell, UICollectionViewCell) automatically have pointer effects. Do not add custom `UIPointerInteraction` to these unless you need a non-standard effect.

## Apple Pencil and PencilKit

### Basic PencilKit Setup

```swift
import PencilKit

struct DrawingView: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .pencilOnly  // Only Pencil draws; finger scrolls
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)
        canvasView.backgroundColor = .systemBackground

        // Show the system tool picker
        if let windowScene = canvasView.window?.windowScene {
            let toolPicker = PKToolPicker.shared(for: windowScene)
            toolPicker?.setVisible(true, forFirstResponder: canvasView)
            toolPicker?.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: DrawingView

        init(_ parent: DrawingView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}
```

### Drawing Policy

```swift
// Drawing policy controls what input triggers drawing
canvasView.drawingPolicy = .pencilOnly   // Pencil draws, finger scrolls/gestures
canvasView.drawingPolicy = .anyInput     // Both pencil and finger draw
canvasView.drawingPolicy = .default      // System default (pencilOnly on iPad with Pencil)
```

### Touch Type Filtering (Non-PencilKit Views)

For custom drawing or annotation views that do not use PencilKit, filter touch types:

```swift
class CustomDrawingView: UIView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        switch touch.type {
        case .pencil:
            // Handle pencil input for drawing
            startDrawing(at: touch.location(in: self))
        case .direct, .indirect:
            // Handle finger/trackpad for navigation
            startPanning(at: touch.location(in: self))
        @unknown default:
            break
        }
    }
}
```

### Extracting Drawing Data

```swift
// Save drawing as data
let drawingData = drawing.dataRepresentation()

// Load drawing from data
if let restored = try? PKDrawing(data: drawingData) {
    canvasView.drawing = restored
}

// Generate image from drawing
let image = drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)

// Access individual strokes
for stroke in drawing.strokes {
    let ink = stroke.ink        // Ink type and color
    let path = stroke.path      // Array of PKStrokePoint
    let bounds = stroke.renderBounds
}
```

### UIPencilInteraction (Double Tap)

Handle Apple Pencil double-tap gesture (Pencil 2nd generation):

```swift
class DrawingViewController: UIViewController, UIPencilInteractionDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        view.addInteraction(pencilInteraction)
    }

    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        // Respond to the user's preferred action
        switch UIPencilInteraction.preferredTapAction {
        case .switchEraser:
            toggleEraser()
        case .showColorPalette:
            showColorPicker()
        case .switchPrevious:
            switchToPreviousTool()
        case .showInkAttributes:
            showInkSettings()
        case .ignore:
            break
        @unknown default:
            break
        }
    }
}
```

### UIIndirectScribbleInteraction

Scribble lets users write with Apple Pencil into text fields. Standard UITextField and UITextView support it automatically. For custom text input views:

```swift
class CustomTextView: UIView, UIIndirectScribbleInteractionDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let scribbleInteraction = UIIndirectScribbleInteraction(delegate: self)
        addInteraction(scribbleInteraction)
    }

    required init?(coder: NSCoder) { fatalError() }

    func indirectScribbleInteraction(
        _ interaction: UIIndirectScribbleInteraction,
        isElementFocused elementIdentifier: String
    ) -> Bool {
        return elementIdentifier == focusedElementID
    }

    func indirectScribbleInteraction(
        _ interaction: UIIndirectScribbleInteraction,
        focusElementIfNeeded elementIdentifier: String,
        referencePoint point: CGPoint,
        completion: @escaping ((UIResponder & UITextInput)?) -> Void
    ) {
        focusElement(elementIdentifier)
        completion(textInputResponder)
    }

    func indirectScribbleInteraction(
        _ interaction: UIIndirectScribbleInteraction,
        requestElementsIn rect: CGRect,
        completion: @escaping ([String]) -> Void
    ) {
        let elements = textElements(in: rect).map(\.identifier)
        completion(elements)
    }
}
```

## Focus System

### SwiftUI Focus

```swift
struct SearchableList: View {
    @FocusState private var isSearchFocused: Bool
    @State private var searchText = ""

    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .focused($isSearchFocused)

            List(filteredItems) { item in
                ItemRow(item: item)
            }
        }
        .onAppear {
            isSearchFocused = true // Auto-focus search field
        }
        .keyboardShortcut("f", modifiers: .command) // Cmd+F focuses search
    }
}
```

### Focus with Enum

```swift
enum FormField: Hashable {
    case title
    case description
    case tags
}

struct FormView: View {
    @FocusState private var focusedField: FormField?
    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""

    var body: some View {
        Form {
            TextField("Title", text: $title)
                .focused($focusedField, equals: .title)

            TextField("Description", text: $description)
                .focused($focusedField, equals: .description)

            TextField("Tags", text: $tags)
                .focused($focusedField, equals: .tags)
        }
        .onSubmit {
            // Move focus to next field
            switch focusedField {
            case .title: focusedField = .description
            case .description: focusedField = .tags
            case .tags: focusedField = nil
            case nil: break
            }
        }
    }
}
```

### Focusable Views (Non-Text)

```swift
struct FocusableCard: View {
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Text("Card")
        }
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()  // Disable default focus ring if custom styling
        .border(isFocused ? Color.blue : Color.clear, width: 2)
        .onKeyPress(.return) {
            activateCard()
            return .handled
        }
    }
}
```

### FocusedValue for Cross-View Communication

```swift
// Define focused value key
struct FocusedDocumentKey: FocusedValueKey {
    typealias Value = Document
}

extension FocusedValues {
    var focusedDocument: Document? {
        get { self[FocusedDocumentKey.self] }
        set { self[FocusedDocumentKey.self] = newValue }
    }
}

// Set from the focused view
struct DocumentView: View {
    let document: Document

    var body: some View {
        content
            .focusedValue(\.focusedDocument, document)
    }
}

// Read from commands/menus
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .pasteboard) {
                Button("Export Document") {
                    // Uses focused document from whichever window is focused
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}
```

## Common Mistakes

### No Keyboard Shortcuts for Primary Actions

```swift
// ❌ Wrong -- no shortcuts; keyboard users must tap screen
Button("New") { createNew() }
Button("Delete") { deleteSelected() }

// ✅ Right -- discoverable shortcuts for primary actions
Button("New") { createNew() }
    .keyboardShortcut("n", modifiers: .command)
Button("Delete") { deleteSelected() }
    .keyboardShortcut(.delete, modifiers: .command)
```

### Missing Hover Effects

```swift
// ❌ Wrong -- no visual feedback with trackpad/mouse
Button("Action") { doSomething() }

// ✅ Right -- pointer gets hover effect
Button("Action") { doSomething() }
    .hoverEffect()
```

Note: standard SwiftUI `Button` already has basic pointer behavior. Add `.hoverEffect()` to custom interactive elements built with `.onTapGesture`.

### Drawing with Finger When Pencil Is Available

```swift
// ❌ Wrong -- both finger and pencil draw, user cannot scroll
canvasView.drawingPolicy = .anyInput

// ✅ Right -- pencil draws, finger scrolls
canvasView.drawingPolicy = .pencilOnly
```

### Not Respecting Pencil Double-Tap Preference

```swift
// ❌ Wrong -- hardcoded double-tap behavior
func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    toggleEraser()  // Ignores user preference
}

// ✅ Right -- check user's preferred action
func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    switch UIPencilInteraction.preferredTapAction {
    case .switchEraser: toggleEraser()
    case .showColorPalette: showColorPicker()
    case .switchPrevious: switchToPreviousTool()
    case .showInkAttributes: showInkSettings()
    case .ignore: break
    @unknown default: break
    }
}
```

## Checklist

- [ ] Primary actions have `.keyboardShortcut()` modifiers
- [ ] Shortcuts follow platform conventions (Cmd+S save, Cmd+N new, Cmd+Z undo)
- [ ] Custom interactive elements have `.hoverEffect()`
- [ ] PencilKit drawing policy is `.pencilOnly` (not `.anyInput`) unless intentional
- [ ] Pencil double-tap respects `UIPencilInteraction.preferredTapAction`
- [ ] Focus management enables Tab/Shift+Tab navigation through form fields
- [ ] `@FocusState` used for programmatic focus control
- [ ] Context menus on relevant items (also serve right-click on pointer devices)
- [ ] Arrow key navigation for grid/list views with keyboard
- [ ] Scribble works in custom text input views (UIIndirectScribbleInteraction)
