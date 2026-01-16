# Localization Patterns

Best practices for internationalization (i18n) in iOS/macOS apps using String Catalogs and modern Swift APIs.

## String Catalogs (iOS 16+)

### Structure

String Catalogs (.xcstrings) are JSON files with a visual editor in Xcode:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "welcome_message" : {
      "localizations" : {
        "en" : { "stringUnit" : { "value" : "Welcome!" } },
        "es" : { "stringUnit" : { "value" : "¡Bienvenido!" } },
        "ja" : { "stringUnit" : { "value" : "ようこそ！" } }
      }
    }
  }
}
```

### Automatic Extraction

Xcode automatically extracts localizable strings:

```swift
// These are automatically added to String Catalog
Text("Hello, World!")
Button("Save") { }
Label("Settings", systemImage: "gear")
```

### Manual Keys

For non-UI strings or custom keys:

```swift
let message = String(localized: "custom_key")
let greeting = String(localized: "greeting \(name)")
```

## Type-Safe String Access

### Basic Enum

```swift
enum L10n {
    // MARK: - General
    static let appName = String(localized: "app_name")
    static let ok = String(localized: "ok")
    static let cancel = String(localized: "cancel")
    static let done = String(localized: "done")
    static let error = String(localized: "error")

    // MARK: - Onboarding
    enum Onboarding {
        static let welcomeTitle = String(localized: "onboarding.welcome.title")
        static let welcomeMessage = String(localized: "onboarding.welcome.message")
        static let getStarted = String(localized: "onboarding.get_started")
    }

    // MARK: - Settings
    enum Settings {
        static let title = String(localized: "settings.title")
        static let appearance = String(localized: "settings.appearance")
        static let notifications = String(localized: "settings.notifications")
        static let about = String(localized: "settings.about")
    }

    // MARK: - Errors
    enum Error {
        static let networkFailed = String(localized: "error.network_failed")
        static let saveFailed = String(localized: "error.save_failed")
        static func custom(_ message: String) -> String {
            String(localized: "error.custom \(message)")
        }
    }
}
```

### With Interpolation

```swift
enum L10n {
    // "greeting" = "Hello, %@!"
    static func greeting(_ name: String) -> String {
        String(localized: "greeting \(name)")
    }

    // "items_selected" = "%lld items selected"
    static func itemsSelected(_ count: Int) -> String {
        String(localized: "items_selected \(count)")
    }

    // "file_size" = "File size: %@ MB"
    static func fileSize(_ size: Double) -> String {
        String(localized: "file_size \(size, format: .number.precision(.fractionLength(1)))")
    }
}
```

## Pluralization

### In String Catalog

Define plural variations in Xcode's String Catalog editor:

| Key | Plural Category | Value |
|-----|-----------------|-------|
| items_count | zero | No items |
| items_count | one | 1 item |
| items_count | other | %lld items |

### Usage

```swift
// Automatic plural selection based on count
let count = 5
Text(String(localized: "items_count \(count)"))  // "5 items"

// In L10n enum
enum L10n {
    static func itemsCount(_ count: Int) -> String {
        String(localized: "items_count \(count)")
    }
}
```

### Complex Plurals

Some languages have multiple plural categories:

| Category | Languages | Example (items) |
|----------|-----------|-----------------|
| zero | Arabic, Latvian, Welsh | 0 items |
| one | English, German, Spanish | 1 item |
| two | Arabic, Welsh | 2 items |
| few | Russian, Polish, Czech | 2-4 items |
| many | Russian, Polish, Arabic | 5-20 items |
| other | All | Default |

## Device Variations

### In String Catalog

Set device-specific variations:

| Key | Device | Value |
|-----|--------|-------|
| tap_to_continue | iPhone | Tap to continue |
| tap_to_continue | iPad | Tap or use keyboard |
| tap_to_continue | Mac | Click to continue |

### Programmatic Check

```swift
#if os(iOS)
if UIDevice.current.userInterfaceIdiom == .pad {
    // iPad-specific
} else {
    // iPhone-specific
}
#elseif os(macOS)
// Mac-specific
#endif
```

## Runtime Language Switching

### Language Manager

```swift
import SwiftUI

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    var currentLanguage: String {
        didSet {
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }

    var currentLocale: Locale {
        Locale(identifier: currentLanguage)
    }

    private init() {
        currentLanguage = Locale.preferredLanguages.first ?? "en"
    }

    var supportedLanguages: [String] {
        Bundle.main.localizations.filter { $0 != "Base" }
    }

    func displayName(for languageCode: String) -> String {
        Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode
    }
}
```

### Language Picker

```swift
struct LanguagePicker: View {
    @Bindable private var manager = LocalizationManager.shared

    var body: some View {
        Picker("Language", selection: $manager.currentLanguage) {
            ForEach(manager.supportedLanguages, id: \.self) { code in
                Text(manager.displayName(for: code))
                    .tag(code)
            }
        }
    }
}
```

### Note on Runtime Switching

Full runtime language switching requires app restart. For in-app switching without restart:

```swift
// Environment-based approach (limited to SwiftUI)
struct ContentView: View {
    @State private var locale = Locale.current

    var body: some View {
        MainContent()
            .environment(\.locale, locale)
    }
}
```

## Formatting

### Numbers

```swift
// Currency
Text(price, format: .currency(code: "USD"))

// Percentage
Text(0.75, format: .percent)

// Custom number format
Text(1234.5, format: .number.precision(.fractionLength(2)))
```

### Dates

```swift
// Relative (e.g., "2 days ago")
Text(date, format: .relative(presentation: .named))

// Specific format
Text(date, format: .dateTime.month(.wide).day().year())

// Range
Text(startDate...endDate)
```

### Lists

```swift
let names = ["Alice", "Bob", "Charlie"]

// "Alice, Bob, and Charlie"
Text(names, format: .list(type: .and))

// "Alice, Bob, or Charlie"
Text(names, format: .list(type: .or))
```

### Measurements

```swift
let distance = Measurement(value: 5, unit: UnitLength.kilometers)
Text(distance, format: .measurement(width: .abbreviated))  // "5 km"
```

## RTL (Right-to-Left) Support

### Automatic Layout

SwiftUI handles RTL automatically. Use semantic modifiers:

```swift
// Good - Semantic
HStack {
    Text("Label")
    Spacer()
    Text("Value")
}

// Avoid - Absolute positioning for text flow
.padding(.leading, 16)  // Use this, not .left
.padding(.trailing, 16) // Use this, not .right
```

### Images

```swift
// Flip image for RTL
Image(systemName: "arrow.right")
    .flipsForRightToLeftLayoutDirection(true)
```

### Manual RTL Detection

```swift
struct RTLAwareView: View {
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        if layoutDirection == .rightToLeft {
            // RTL-specific layout
        } else {
            // LTR layout
        }
    }
}
```

## SwiftUI Preview Helpers

```swift
import SwiftUI

// Preview in multiple locales
#Preview("English") {
    ContentView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Spanish") {
    ContentView()
        .environment(\.locale, Locale(identifier: "es"))
}

#Preview("Japanese") {
    ContentView()
        .environment(\.locale, Locale(identifier: "ja"))
}

#Preview("Arabic (RTL)") {
    ContentView()
        .environment(\.locale, Locale(identifier: "ar"))
        .environment(\.layoutDirection, .rightToLeft)
}
```

### Locale Preview Modifier

```swift
extension View {
    func previewLocales(_ locales: [String] = ["en", "es", "ja", "ar"]) -> some View {
        ForEach(locales, id: \.self) { locale in
            self
                .environment(\.locale, Locale(identifier: locale))
                .previewDisplayName(Locale.current.localizedString(forIdentifier: locale) ?? locale)
        }
    }
}

// Usage
#Preview {
    ContentView()
        .previewLocales()
}
```

## Accessibility

### VoiceOver Localization

```swift
Button(action: { }) {
    Image(systemName: "heart.fill")
}
.accessibilityLabel(String(localized: "accessibility.favorite"))
.accessibilityHint(String(localized: "accessibility.favorite_hint"))
```

### Dynamic Type with Localization

```swift
Text(L10n.longDescription)
    .font(.body)
    .minimumScaleFactor(0.5)  // Allow text to scale down if needed
```

## Testing

### Unit Tests

```swift
import XCTest

final class LocalizationTests: XCTestCase {
    func testAllKeysHaveTranslations() {
        let bundle = Bundle.main
        let localizations = bundle.localizations.filter { $0 != "Base" }

        // Get all keys from base localization
        let baseKeys = getAllKeys(for: "en", in: bundle)

        for language in localizations {
            let keys = getAllKeys(for: language, in: bundle)
            XCTAssertEqual(baseKeys, keys, "Missing translations in \(language)")
        }
    }
}
```

### Pseudo-Localization

Test with pseudo-localized strings to catch layout issues:

```swift
#if DEBUG
extension String {
    var pseudoLocalized: String {
        // Add accents and padding to reveal truncation/layout issues
        "[[ \(self.map { "̈\($0)" }.joined()) ]]"
    }
}
#endif
```

## Migration from .strings

### Automatic Migration

1. Right-click existing .strings file
2. Select "Migrate to String Catalog..."
3. Xcode creates .xcstrings with all translations

### Manual Considerations

- InfoPlist.strings → InfoPlist.xcstrings
- Localizable.strings → Localizable.xcstrings
- Storyboard/XIB strings migrate automatically

## Export/Import for Translation

### Export

```bash
# Command line
xcodebuild -exportLocalizations -project YourApp.xcodeproj -localizationPath ./Localizations

# Or in Xcode: Product > Export Localizations...
```

### Import

```bash
xcodebuild -importLocalizations -project YourApp.xcodeproj -localizationPath ./Localizations/es.xcloc

# Or in Xcode: Product > Import Localizations...
```

### XLIFF Format

Exported .xcloc packages contain XLIFF files that translators can edit with standard translation tools.
