---
name: design-system
description: Build-time design-system rules that keep an Apple app cheap to restyle — role-named tokens, text styles that carry case and tracking, shared components with a ContentStateView, small views, identifier-based UI tests, and SwiftLint enforcement with a shrinking baseline. iOS, iPadOS, macOS, watchOS. Use when starting an app's UI, setting up tokens, adopting a designer's Figma/Sketch system, or preparing for or doing a redesign.
allowed-tools: [Read, Write, Edit, Glob, Grep]
last_verified: 2026-11-04
review_by: 2027-06-22
---

# Design System (build-time rules)

How cheap a redesign is depends almost entirely on how styling was written,
not on how big the app is. In a real ~45k-line SwiftUI app going through a
full redesign, about a third of the estimate was **pure restyling** of screens
that already worked — because of hand-set font sizes and colours, case applied
at call sites, appearance-named tokens, per-screen loading/empty states,
3,000-line view files, and UI tests that matched visible text.

This skill is the set of rules that prevents that. `design/typography` covers
*choosing* type and Dynamic Type; `product/ux-spec` writes a
`DESIGN_SYSTEM.md` spec. This skill is about how the code is written so the
look can change in one place.

## When This Skill Activates

- Starting the UI of a new app (before the first screen)
- Setting up colour/spacing/type tokens, or adopting a designer's system
- A redesign is coming, or restyling is taking longer than it should
- Reviewing UI code for restyle cost

## Styling

1. **No raw style values in views.** Fonts, colours, spacing, radius and
   shadow come from tokens. Allowed: `0`, and an icon-size token.
2. **Name tokens by role, mirroring the designer's variables.** `Text/Primary`
   → `textPrimary`, `Action/Primary/Background` → `actionPrimaryBackground`.
   Never by appearance (`label2`, `grey600`, `tagSemibold`) — appearance
   names are exactly what a redesign changes.
3. **One text style = family + size + weight + line height + tracking +
   case**, applied with **one** modifier. No `.textCase`, `.tracking`,
   `.kerning` or `.uppercased()` at call sites. **User-generated text keeps
   its original case** — provide an `.original` variant.
4. **Spacing and radius come from a scale** (`xxs…xxl`, `s/m/l/pill`), not
   loose numbers.
5. **Custom fonts:** verify registration at launch in debug builds, and scale
   with Dynamic Type via `relativeTo:`. A font declared in `UIAppFonts` but
   missing from the bundle silently falls back to the system font — teams
   have shipped that for months.
6. **Enforce 1–3 with SwiftLint** (`rules/swiftlint.yml`), with a baseline
   that only shrinks (see Enforcement).

```swift
// Tokens — role names, one file
enum Spacing { static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 16, l: CGFloat = 24 }
enum Radius  { static let s: CGFloat = 6, m: CGFloat = 12, pill: CGFloat = 999 }
extension Color {
    static let textPrimary = Color("Text/Primary")          // asset catalog, light/dark
    static let actionPrimaryBackground = Color("Action/Primary/Background")
}

// Text style carries case + tracking — call sites never do
struct AppTextStyle: Sendable {
    var font: Font
    var lineSpacing: CGFloat = 0
    var tracking: CGFloat = 0
    var textCase: Text.Case? = nil

    /// Same style without the case transform — for names, titles users typed, etc.
    var original: AppTextStyle { var s = self; s.textCase = nil; return s }
}
extension AppTextStyle {
    static let body  = AppTextStyle(font: .custom("Inter-Regular", size: 17, relativeTo: .body), lineSpacing: 4)
    static let label = AppTextStyle(font: .custom("Inter-SemiBold", size: 12, relativeTo: .caption),
                                    tracking: 0.6, textCase: .uppercase)
}
extension View {
    func appText(_ style: AppTextStyle) -> some View {
        font(style.font).lineSpacing(style.lineSpacing)
            .tracking(style.tracking).textCase(style.textCase)
    }
}

// Call sites
Text("Recent").appText(.label)               // ✅ designed label
Text(item.ownerName).appText(.label.original) // ✅ user text keeps its case
Text("Recent".uppercased()).tracking(0.6)     // ❌ restyle = hunt every call site
```

```swift
// Debug-time font check (call once at launch)
#if DEBUG
func assertCustomFontsRegistered() {
    for name in ["Inter-Regular", "Inter-SemiBold"] {
        #if canImport(UIKit)
        assert(UIFont(name: name, size: 12) != nil, "Font \(name) not bundled/registered")
        #elseif canImport(AppKit)
        assert(NSFont(name: name, size: 12) != nil, "Font \(name) not bundled/registered")
        #endif
    }
}
#endif
```

## Components

7. **Build shared components before screens:** button (variants + loading +
   disabled), card, chip, text field with error state, search field, sheet,
   confirm sheet, toast with undo, and **`ContentStateView`**.
8. **Every async or list screen renders through `ContentStateView`** —
   loading (skeleton), empty, error-with-retry, offline. No ad-hoc spinners
   or "No results" `Text` per screen.
9. **Variants go into the component**, never a copied-and-tweaked local
   version inside a screen.

```swift
enum ContentState<Value> { case loading, empty, failed, offline, loaded(Value) }

struct ContentStateView<Value, Content: View>: View {
    let state: ContentState<Value>
    var emptyTitle: LocalizedStringKey = "Nothing here yet"
    var retry: (() -> Void)? = nil
    @ViewBuilder var content: (Value) -> Content

    var body: some View {
        switch state {
        case .loading:  ProgressView()   // swap for the app's skeleton
        case .empty:    ContentUnavailableView(emptyTitle, systemImage: "tray")
        case .failed:   FailedStateView(retry: retry)
        case .offline:  ContentUnavailableView("You're Offline", systemImage: "wifi.slash")
        case .loaded(let value): content(value)
        }
    }
}

private struct FailedStateView: View {
    let retry: (() -> Void)?
    var body: some View {
        ContentUnavailableView {
            Label("Couldn't Load", systemImage: "exclamationmark.triangle")
        } actions: {
            if let retry { Button("Try Again", action: retry) }
        }
    }
}
```
`ContentUnavailableView` needs iOS 17 / macOS 14 / watchOS 10; below that,
build the same three states from a `VStack`.

## Screen structure

10. **View files under ~300 lines** — split by section into subviews in
    their own files. Large files are where layout and logic tangle, and they
    are the slowest to restyle (also: `swift/code-size`).
11. **Logic in `@Observable` models/services**; views read state and send
    actions.
12. **Formatting through shared formatters** — money + currency, units,
    dates, distances, counts. Never format by hand in a view.
13. **`#Preview` for every state:** default, loading, empty, error, long
    text, and large Dynamic Type (iOS) / narrow + wide window (macOS) /
    smallest + largest watch (watchOS).

## Data

14. **Model the domain, not today's screen:** typed media items instead of
    `[String]` URLs, a structured `Rate` instead of a bare `Double`, a
    preferences map instead of N booleans. A redesign that adds one field
    shouldn't rewrite the model.
15. **Schema changes ship with a migration/backfill** and updated access
    rules (CloudKit/server).
16. **Status enums decode unknown values to `.unknown`**, so a server adding
    a status doesn't break older builds:

```swift
enum OrderStatus: String, Decodable {
    case pending, shipped, delivered, unknown
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = OrderStatus(rawValue: raw) ?? .unknown
    }
}
```

## Tests

17. **UI tests find elements by `accessibilityIdentifier`, never visible
    text.** A copy or case change shouldn't break the test suite. Give every
    interactive or asserted element an identifier.
18. **Snapshot-test the shared components** — each variant and state. A
    token change then shows up as a reviewable image diff in one place
    (`testing/snapshot-test-setup`).

```swift
Button("Save", action: save).accessibilityIdentifier("editor.save")
app.buttons["editor.save"].tap()        // ✅ survives "Save" → "Done"
app.buttons["Save"].tap()               // ❌ breaks on any copy change
```

## Process

19. **Design system first, screens second.** Tokens, text styles and shared
    components exist before the first feature screen.
20. **Developer review of each design section before it's final** — flag
    costly items early (paid services, large uploads, location, new backend
    work).
21. **Build each phase against a named or dated design version.** Changes
    after that are change requests, not defects.
22. **Ask designers for** a small set of text styles, role-named colour
    variables and a real spacing scale — it's what makes 1–4 possible.

## Enforcement

`rules/swiftlint.yml` adds custom rules for raw font sizes, raw colours,
numeric padding/radius, and call-site case/tracking. Merge it into the
project's `.swiftlint.yml` and **exclude the token/style files** (the rules
already skip paths containing `DesignSystem/`, `Tokens/`, `Theme/`, `Styles/`).

Existing codebase: freeze current violations, then let the baseline only
shrink — new code must be clean, migrated files leave the baseline:
```bash
swiftlint lint --write-baseline .swiftlint-baseline.json    # once
swiftlint lint --strict --baseline .swiftlint-baseline.json # every build / CI
```
Measuring how much styling bypasses the tokens (the "design debt" ratio) is
the first number to know before quoting any redesign.

## Platform notes

- **iOS / iPadOS:** text styles via `Font.custom(_:size:relativeTo:)` or the
  system styles; `@ScaledMetric` for spacing that should grow with type;
  components adapt to size classes rather than screens branching on them.
- **macOS:** no Dynamic Type — design at 100%; semantic `NSColor`
  equivalents in the asset catalog; respect control sizes (`.controlSize`);
  **hover and focus states are part of every interactive component**.
- **watchOS:** compact text styles and a smaller spacing scale; components
  sized for glanceable states and the Digital Crown; skip glass-heavy
  treatments.

## Output Format

Restyle-cost review: `File | Rule # | Finding | Fix` — group by rule, count
raw values vs token uses, and list files over 300/500 lines.

## References

- https://developer.apple.com/design/human-interface-guidelines/color
- https://developer.apple.com/design/human-interface-guidelines/typography
- https://developer.apple.com/documentation/swiftui/contentunavailableview
- Related skills: `design/typography` (type choice, Dynamic Type), `product/ux-spec` (DESIGN_SYSTEM.md spec), `swift/code-size` (size thresholds), `testing/snapshot-test-setup`, `generators/accessibility-generator`
