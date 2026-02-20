---
name: text-editing
description: Styled text display and rich text editing in SwiftUI using Text, AttributedString, and TextEditor with formatting controls. Use when implementing rich text editing or styled text display.
allowed-tools: [Read, Glob, Grep]
---

# Styled Text Editing

Patterns for displaying styled text and building rich text editors in SwiftUI. Covers Text styling, AttributedString, TextEditor with selection-based formatting, and custom formatting definitions.

## When This Skill Activates

Use this skill when the user:
- Wants to display styled or formatted text
- Needs rich text editing with bold/italic/underline controls
- Asks about AttributedString or TextEditor
- Wants text formatting toolbars
- Asks about Markdown rendering in Text views
- Needs custom text attributes or formatting constraints
- Wants selection-based text formatting

## Decision Tree

```
What text feature do you need?
|
+- Display styled read-only text
|  +- Simple styling (one style) -> Text Styling section below
|  +- Mixed styles in one string -> AttributedString section below
|  +- Markdown content -> Markdown section below
|
+- Edit plain text
|  +- TextEditor(text: $stringBinding)
|
+- Edit rich/styled text
|  +- Basic rich editor -> Rich Text Editing section below
|  +- With formatting toolbar -> Formatting Controls section below
|  +- With custom constraints -> Custom Formatting section below
```

## API Availability

| API | Minimum Version | Notes |
|-----|----------------|-------|
| `Text` with modifiers | iOS 13 | .font(), .bold(), .italic() |
| `TextEditor(text:)` | iOS 14 | Plain string binding |
| `.foregroundStyle()` | iOS 15 | Preferred over .foregroundColor() |
| `AttributedString` | iOS 15 | Rich text model |
| `.bold(condition)` | iOS 16 | Conditional bold/italic |
| `.underline(pattern:)` | iOS 16 | Dash, dot patterns |
| `TextEditor(text:selection:)` | iOS 18 | AttributedString + selection |
| `AttributedTextSelection` | iOS 18 | Selection-based formatting |
| `text.transformAttributes(in:)` | iOS 18 | Modify attributes in selection |
| `AttributedTextFormattingDefinition` | iOS 18 | Custom formatting constraints |
| `@Environment(\.fontResolutionContext)` | iOS 18 | Resolve font properties |

## Top 5 Mistakes

| # | Mistake | Fix |
|---|---------|-----|
| 1 | Using `.foregroundColor()` on new projects | Use `.foregroundStyle()` — supports gradients and ShapeStyle |
| 2 | `.animation(.spring())` without `value:` on text | Deprecated in iOS 15 — always pass `value:` parameter |
| 3 | Expecting full Markdown in `Text` | Text only supports inline Markdown: **bold**, *italic*, [links]. No lists, tables, code blocks, images |
| 4 | Creating new AttributedString instances on every body evaluation | Cache complex AttributedString objects in @State or computed properties outside body |
| 5 | Using `TextEditor(text: $string)` for rich text | Use `TextEditor(text: $attributedString, selection: $selection)` with AttributedString binding (iOS 18+) |

## Text Styling Quick Reference

```swift
// Font
Text("Hello").font(.headline)
Text("Custom").font(.system(size: 24, design: .rounded))

// Weight
Text("Bold").fontWeight(.bold)

// Color — prefer foregroundStyle over foregroundColor
Text("Styled").foregroundStyle(.red)
Text("Gradient").foregroundStyle(
    .linearGradient(colors: [.yellow, .blue], startPoint: .top, endPoint: .bottom)
)

// Decorations
Text("Bold").bold()
Text("Conditional").bold(someCondition)
Text("Underline").underline(true, pattern: .dash, color: .blue)
Text("Strike").strikethrough(true, pattern: .dot, color: .red)

// Layout
Text("Centered").multilineTextAlignment(.center)
Text("Spaced").lineSpacing(10)
Text("Truncated").lineLimit(2).truncationMode(.tail)
```

## AttributedString

```swift
// Create and style ranges
var text = AttributedString("Red and Blue")
if let redRange = text.range(of: "Red") {
    text[redRange].foregroundColor = .red
    text[redRange].font = .headline
}
if let blueRange = text.range(of: "Blue") {
    text[blueRange].foregroundColor = .blue
    text[blueRange].underlineStyle = .single
}

// Display
Text(text)
```

### Available Attributes

| Attribute | Type | Example |
|-----------|------|---------|
| `.font` | Font | `.headline` |
| `.foregroundColor` | Color | `.red` |
| `.backgroundColor` | Color | `.yellow` |
| `.underlineStyle` | UnderlineStyle | `.single` |
| `.underlineColor` | Color | `.blue` |
| `.strikethroughStyle` | UnderlineStyle | `.single` |
| `.strikethroughColor` | Color | `.red` |
| `.inlinePresentationIntent` | InlinePresentationIntent | `.stronglyEmphasized` (bold), `.emphasized` (italic) |

## Rich Text Editing (iOS 18+)

```swift
struct RichTextEditorView: View {
    @State private var text = AttributedString("Select text to format")
    @State private var selection = AttributedTextSelection()

    @Environment(\.fontResolutionContext) private var fontResolutionContext

    var body: some View {
        VStack {
            TextEditor(text: $text, selection: $selection)
                .frame(height: 200)

            HStack {
                Button(action: toggleBold) {
                    Image(systemName: "bold")
                }
                Button(action: toggleItalic) {
                    Image(systemName: "italic")
                }
                Button(action: toggleUnderline) {
                    Image(systemName: "underline")
                }
            }
        }
    }

    private func toggleBold() {
        text.transformAttributes(in: &selection) {
            let font = $0.font ?? .default
            let resolved = font.resolve(in: fontResolutionContext)
            $0.font = font.bold(!resolved.isBold)
        }
    }

    private func toggleItalic() {
        text.transformAttributes(in: &selection) {
            let font = $0.font ?? .default
            let resolved = font.resolve(in: fontResolutionContext)
            $0.font = font.italic(!resolved.isItalic)
        }
    }

    private func toggleUnderline() {
        text.transformAttributes(in: &selection) {
            if $0.underlineStyle != nil {
                $0.underlineStyle = nil
            } else {
                $0.underlineStyle = .single
            }
        }
    }
}
```

### Reading Selection Attributes

```swift
// Get current attributes at the selection/cursor
let attributes = selection.typingAttributes(in: text)
let currentColor = attributes.foregroundColor ?? .primary

// Set color on selection
text.transformAttributes(in: &selection) {
    $0.foregroundColor = .blue
}
```

## Custom Formatting Definition (iOS 18+)

Constrain which formatting options are available in the editor:

```swift
struct MyTextFormatting: AttributedTextFormattingDefinition {
    typealias Scope = AttributeScopes.SwiftUIAttributes

    static let fontWeight = ValueConstraint(
        \.font,
        constraint: { font in
            guard let font = font else { return nil }
            let weight = font.resolve().weight
            return font.weight(weight == .bold ? .regular : .bold)
        }
    )
}

// Apply to TextEditor
TextEditor(text: $text, selection: $selection)
    .textFormattingDefinition(MyTextFormatting.self)
```

## Markdown in Text

```swift
// Inline markdown support
Text("This is **bold** and *italic* text")
Text("Visit [Apple](https://www.apple.com)")
Text("Code: `inline code`")
```

### Markdown Limitations

Text supports only **inline** Markdown:
- ✅ Bold (`**text**`), italic (`*text*`), links, inline code
- ❌ Line breaks, block formatting, lists, tables, code blocks, images, block quotes

## Review Checklist

### Text Display
- [ ] Using `.foregroundStyle()` instead of deprecated `.foregroundColor()`
- [ ] `.lineLimit()` paired with `.help()` tooltip or `.textSelection(.enabled)` for truncated text
- [ ] Dynamic Type supported — using system font styles, not hardcoded sizes
- [ ] Colors adapt to dark mode — using system colors or semantic styles

### AttributedString
- [ ] Complex AttributedString cached in @State, not recreated in body
- [ ] Range lookups use safe `if let range = text.range(of:)` pattern
- [ ] Appropriate attributes used (`.inlinePresentationIntent` for semantic bold/italic)

### TextEditor
- [ ] Rich text uses `TextEditor(text: $attributedString, selection: $selection)` (iOS 18+)
- [ ] Formatting toolbar uses `text.transformAttributes(in: &selection)` pattern
- [ ] Font resolution uses `@Environment(\.fontResolutionContext)` for toggle logic
- [ ] Accessibility labels provided for formatting buttons

### Localization
- [ ] User-facing strings use `LocalizedStringKey`
- [ ] Markdown in localized strings uses `Text(LocalizedStringKey("**Bold** text"))`

## References

- [SwiftUI Text and Symbol Modifiers](https://developer.apple.com/documentation/SwiftUI/View-Text-and-Symbols)
- [Building Rich SwiftUI Text Experiences](https://developer.apple.com/documentation/SwiftUI/building-rich-swiftui-text-experiences)
- [AttributedString Documentation](https://developer.apple.com/documentation/Foundation/AttributedString)
- [TextEditor Documentation](https://developer.apple.com/documentation/SwiftUI/TextEditor)
