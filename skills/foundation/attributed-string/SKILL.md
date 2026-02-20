---
name: attributed-string
description: AttributedString patterns for rich text formatting, alignment, selection, and SwiftUI integration. Use when working with styled text, text editing, or AttributedString APIs.
allowed-tools: [Read, Glob, Grep]
---

# AttributedString Patterns

Correct API shapes and patterns for Foundation's `AttributedString`. Covers creating styled text, applying attributes to ranges, text alignment, writing direction, line height control, text selection and editing, discontiguous substrings, and SwiftUI integration.

## When This Skill Activates

Use this skill when the user:
- Asks about **AttributedString** creation or manipulation
- Wants to **style text** with fonts, colors, underlines, or other attributes
- Mentions **text alignment**, **writing direction**, or **line height**
- Asks about **text selection** or **text editing** with AttributedString
- Wants to work with **DiscontiguousAttributedSubstring** or **RangeSet**
- Mentions **TextEditor** with **AttributedString** in SwiftUI
- Asks about **rich text** formatting in Swift
- Wants to **replace** or **modify** text within an AttributedString
- Mentions **paragraphStyle**, **textSelectionAffinity**, or **AttributedTextSelection**

## Decision Tree

```
What do you need with AttributedString?
|
+-- Create or style text
|   |
|   +-- Simple inline attributes (font, color)
|   |   --> Creating and Styling section
|   |
|   +-- Paragraph-level formatting (alignment, line height)
|       --> Text Alignment and Formatting section
|
+-- Control text layout
|   |
|   +-- Writing direction (LTR / RTL)
|   |   --> Writing Direction and Line Height section
|   |
|   +-- Line spacing / height
|       --> Writing Direction and Line Height section
|
+-- Edit or select text programmatically
|   |
|   +-- Replace selection with characters or AttributedString
|   |   --> Text Selection and Editing section
|   |
|   +-- Work with multiple non-contiguous ranges
|       --> DiscontiguousAttributedSubstring section
|
+-- Display in SwiftUI
    --> SwiftUI Integration section
```

## API Availability

| API | Minimum Version | Notes |
|-----|----------------|-------|
| `AttributedString` | iOS 15 / macOS 12 | Swift-native replacement for NSAttributedString |
| `AttributedString.font` | iOS 15 / macOS 12 | Inline attribute |
| `AttributedString.foregroundColor` | iOS 15 / macOS 12 | Inline attribute |
| `AttributedString.paragraphStyle` | iOS 15 / macOS 12 | Uses NSMutableParagraphStyle |
| `AttributedString.writingDirection` | iOS 26 / macOS 26 | New in 2025 |
| `AttributedString.LineHeight` | iOS 26 / macOS 26 | `.exact(points:)`, `.multiple(factor:)`, `.loose` |
| `AttributedString.alignment` | iOS 26 / macOS 26 | `.left`, `.center`, `.right` |
| `AttributedTextSelection` | iOS 26 / macOS 26 | Programmatic text selection |
| `replaceSelection(_:withCharacters:)` | iOS 26 / macOS 26 | Replace selection with plain characters |
| `replaceSelection(_:with:)` | iOS 26 / macOS 26 | Replace selection with AttributedString |
| `DiscontiguousAttributedSubstring` | iOS 26 / macOS 26 | Non-contiguous range selections |
| `AttributedString.utf8` | iOS 26 / macOS 26 | UTF-8 code unit view |
| `TextEditor(text:selection:)` with AttributedString | iOS 26 / macOS 26 | SwiftUI rich text editing |
| `.textSelectionAffinity(_:)` | iOS 26 / macOS 26 | Control cursor affinity at line boundaries |

## Top 5 Mistakes

| # | Mistake | Fix |
|---|---------|-----|
| 1 | Using `NSAttributedString` in new Swift code | Use `AttributedString` (iOS 15+) for type-safe, Swift-native attributes |
| 2 | Applying range-based attributes without checking the range exists | Always safely unwrap the result of `text.range(of:)` before subscripting |
| 3 | Forgetting that `AttributedString` is a value type | Mutations require `var`, not `let`; assign attributes after declaring as `var` |
| 4 | Building `NSMutableParagraphStyle` when new alignment API is available | Use `text.alignment = .center` on iOS 26+ instead of manual paragraph styles |
| 5 | Modifying the original string instead of the selection when using `replaceSelection` | Pass the selection as `inout` and let the API update the selection range for you |

## Creating and Styling

### Basic Initialization

```swift
// Plain text
let plain = AttributedString("Hello, world!")

// With attributes applied inline
var bold = AttributedString("Bold text")
bold.font = .boldSystemFont(ofSize: 16)
```

### Applying Attributes to Ranges

```swift
var text = AttributedString("Styled text")
text.foregroundColor = .red
text.backgroundColor = .yellow
text.font = .systemFont(ofSize: 14)

// Attribute on a specific range
if let range = text.range(of: "Styled") {
    text[range].underlineStyle = .single
    text[range].underlineColor = .blue
}
```

### Creating from a Substring

```swift
let source = AttributedString("Hello, world!")
if let range = source.range(of: "world") {
    let substring = source[range]
    let extracted = AttributedString(substring) // standalone copy
}
```

| Pattern | Verdict |
|---------|---------|
| `var text = AttributedString("...")` then mutate | Correct |
| `let text = AttributedString("...")` then mutate | Will not compile -- value type requires `var` |
| Force-unwrapping `text.range(of:)!` | Fragile -- use `if let` or `guard let` |

## Text Alignment and Formatting

### Legacy Approach (iOS 15+)

```swift
var paragraph = AttributedString("Centered paragraph of text")
let style = NSMutableParagraphStyle()
style.alignment = .center
paragraph.paragraphStyle = style
```

### Modern Approach (iOS 26+)

```swift
var paragraph = AttributedString("Centered paragraph of text")
paragraph.alignment = .center
```

Available `TextAlignment` values:

| Value | Description |
|-------|-------------|
| `.left` | Left-aligned text |
| `.right` | Right-aligned text |
| `.center` | Center-aligned text |

## Writing Direction and Line Height

### Writing Direction (iOS 26+)

```swift
var text = AttributedString("Hello عربي")
text.writingDirection = .rightToLeft
```

| Value | Description |
|-------|-------------|
| `.leftToRight` | Standard LTR layout |
| `.rightToLeft` | RTL layout for Arabic, Hebrew, etc. |

### Line Height (iOS 26+)

```swift
var multiline = AttributedString(
    "This is a paragraph\nwith multiple lines\nof text."
)

// Exact point value
multiline.lineHeight = .exact(points: 32)

// Multiplier of the default line height
multiline.lineHeight = .multiple(factor: 2.5)

// System-defined loose spacing
multiline.lineHeight = .loose
```

| Mode | Use Case |
|------|----------|
| `.exact(points:)` | Pixel-perfect designs with fixed line heights |
| `.multiple(factor:)` | Proportional scaling relative to font size |
| `.loose` | Comfortable reading spacing chosen by the system |

## Text Selection and Editing

### Replacing Selected Text (iOS 26+)

```swift
var text = AttributedString("Here is my dog")
var selection = AttributedTextSelection(range: text.range(of: "dog")!)

// Replace with plain characters
text.replaceSelection(&selection, withCharacters: "cat")

// Replace with an AttributedString
let replacement = AttributedString("horse")
text.replaceSelection(&selection, with: replacement)
```

Key points:
- `selection` is passed as `inout` so the API updates the selection range after replacement.
- Use `withCharacters:` for plain text, `with:` for styled replacements.

## DiscontiguousAttributedSubstring

Select and manipulate multiple non-contiguous ranges at once (iOS 26+).

```swift
let text = AttributedString("Select multiple parts of this text")

if let range1 = text.range(of: "Select"),
   let range2 = text.range(of: "text") {
    let rangeSet = RangeSet([range1, range2])
    var substring = text[rangeSet] // DiscontiguousAttributedSubstring
    substring.backgroundColor = .yellow

    // Flatten into a single contiguous AttributedString
    let combined = AttributedString(substring)
}
```

| Operation | Result Type |
|-----------|-------------|
| `text[range]` | `AttributedSubstring` (contiguous) |
| `text[rangeSet]` | `DiscontiguousAttributedSubstring` (non-contiguous) |
| `AttributedString(substring)` | Flattened `AttributedString` copy |

## UTF-8 View

Access raw UTF-8 code units (iOS 26+):

```swift
let text = AttributedString("Hello")
for codeUnit in text.utf8 {
    print(codeUnit)
}
```

## SwiftUI Integration

### TextEditor with AttributedString and Selection (iOS 26+)

```swift
struct SuggestionTextEditor: View {
    @State var text: AttributedString = ""
    @State var selection = AttributedTextSelection()

    var body: some View {
        VStack {
            TextEditor(text: $text, selection: $selection)
            SuggestionsView(
                substrings: getSubstrings(
                    text: text,
                    indices: selection.indices(in: text)
                )
            )
        }
    }
}
```

### Text Selection Affinity

Control which line the cursor appears on when positioned at a line boundary:

```swift
TextEditor(text: $text, selection: $selection)
    .textSelectionAffinity(.upstream)
```

| Value | Behavior |
|-------|----------|
| `.upstream` | Cursor stays at end of previous line |
| `.downstream` | Cursor moves to start of next line |

### Displaying Styled Text in SwiftUI

```swift
// Simple display
Text(attributedString)

// With text selection enabled
Text(attributedString)
    .textSelection(.enabled)
```

## Review Checklist

### Correctness
- [ ] Using `AttributedString` (not `NSAttributedString`) for new Swift code
- [ ] All range lookups safely unwrapped with `if let` or `guard let`
- [ ] String declared as `var` before applying attributes
- [ ] `replaceSelection` passes selection as `inout` (`&selection`)

### Platform and Versioning
- [ ] New APIs (alignment, writingDirection, lineHeight, selection) gated to iOS 26+ / macOS 26+
- [ ] Legacy paragraph style approach used for iOS 15-25 targets
- [ ] Availability checks (`if #available`) wrap newer APIs when supporting older deployment targets

### SwiftUI
- [ ] `TextEditor(text:selection:)` overload used for rich text editing (iOS 26+)
- [ ] `.textSelectionAffinity` applied where cursor behavior at line wraps matters
- [ ] `.textSelection(.enabled)` added to `Text` views that display user content

### Accessibility
- [ ] Foreground and background color combinations meet contrast requirements
- [ ] Styled text does not rely solely on color to convey meaning (add underline, bold, or icons)
- [ ] Writing direction set correctly for RTL language content

## References

- [AttributedString | Apple Developer Documentation](https://developer.apple.com/documentation/foundation/attributedstring)
- [Text | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/text)
- [TextEditor | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/texteditor)
