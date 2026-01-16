# Localization Setup Generator

Generate internationalization (i18n) infrastructure for multi-language support in iOS/macOS apps.

## When to Use

- User wants to localize their app for multiple languages
- User mentions i18n, internationalization, or localization
- User asks about String Catalogs or .strings files
- User wants to support RTL (right-to-left) languages

## Pre-Generation Checks

Before generating, verify:

1. **Existing Localization**
   ```bash
   # Check for existing localization files
   find . -name "*.xcstrings" -o -name "Localizable.strings" 2>/dev/null | head -5
   find . -name "*.lproj" -type d 2>/dev/null | head -5
   ```

2. **Deployment Target**
   ```bash
   # String Catalogs require iOS 16+ / macOS 13+
   grep -r "IPHONEOS_DEPLOYMENT_TARGET\|MACOSX_DEPLOYMENT_TARGET" *.xcodeproj 2>/dev/null
   ```

3. **Project Structure**
   ```bash
   # Find project for adding localization
   find . -name "*.xcodeproj" | head -1
   ```

## Configuration Questions

### 1. Localization Approach
- **String Catalogs** (Recommended, iOS 16+) - Modern, visual editor in Xcode
- **Legacy .strings** - Traditional approach, all iOS versions

### 2. Initial Languages
- English (en) - default
- Which additional languages? (e.g., es, de, fr, ja, zh-Hans)

### 3. Features
- **Pluralization** - Handle "1 item" vs "2 items"
- **Device-specific** - Different strings for iPhone/iPad/Mac
- **SwiftUI Preview** - Preview in different locales

## Generated Files

### String Catalogs (Recommended)
```
Resources/
└── Localizable.xcstrings    # String catalog with all translations
```

### Supporting Code
```
Sources/Localization/
├── LocalizedStrings.swift   # Type-safe string access
├── LocalizationManager.swift # Runtime language switching
└── LocalizedPreview.swift   # SwiftUI preview helpers
```

## Key Features

### Type-Safe String Access

```swift
// Generated enum for type-safe access
enum L10n {
    static let appName = String(localized: "app_name")
    static let welcomeMessage = String(localized: "welcome_message")

    enum Settings {
        static let title = String(localized: "settings_title")
        static let language = String(localized: "settings_language")
    }
}

// Usage
Text(L10n.appName)
Text(L10n.Settings.title)
```

### Pluralization

```swift
// In String Catalog, define plural rules
// key: "items_count"
// variations:
//   - zero: "No items"
//   - one: "1 item"
//   - other: "%lld items"

Text(String(localized: "items_count \(count)",
            defaultValue: "\(count) items"))
```

### String Interpolation

```swift
// In String Catalog:
// key: "greeting"
// value: "Hello, %@!"

let name = "Alice"
Text(String(localized: "greeting \(name)"))
```

### Runtime Language Switching

```swift
// Preview in different locale
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.locale, Locale(identifier: "es"))
    }
}
```

## Integration Steps

### 1. Add String Catalog

1. In Xcode: File > New > File
2. Choose "String Catalog"
3. Name it "Localizable.xcstrings"
4. Add to your app target

### 2. Add Supported Languages

1. Select project in navigator
2. Info tab > Localizations
3. Click + to add languages

### 3. Migrate Existing Strings

If migrating from .strings files:
1. Right-click .strings file
2. "Migrate to String Catalog..."

### 4. Use in SwiftUI

```swift
// Automatic localization
Text("Hello, World!")  // Uses String Catalog automatically

// Explicit localized string
Text(String(localized: "custom_key"))

// With type-safe enum (generated)
Text(L10n.welcomeMessage)
```

### 5. Use in UIKit

```swift
label.text = String(localized: "hello_world")
// or
label.text = NSLocalizedString("hello_world", comment: "Greeting")
```

## Best Practices

### Key Naming Conventions
```
// Good: Descriptive, hierarchical
"settings.appearance.theme"
"onboarding.step1.title"
"error.network.connection_failed"

// Avoid: Vague or hardcoded text as key
"button1"
"Hello, World!"
```

### Comments for Translators
```swift
String(localized: "delete_confirmation",
       comment: "Alert message asking user to confirm deletion")
```

### Formatting
```swift
// Numbers - Use FormatStyle
Text(price, format: .currency(code: "USD"))

// Dates - Use FormatStyle
Text(date, format: .dateTime.month().day())

// Lists - Use ListFormatStyle
Text(items, format: .list(type: .and))
```

### RTL Support
```swift
// Automatic with SwiftUI
// For manual layout adjustments:
.environment(\.layoutDirection, .rightToLeft)
```

## Testing Localization

### In Xcode
1. Edit Scheme > Run > Options
2. Set "App Language" to test language
3. Set "App Region" for number/date formatting

### In SwiftUI Previews
```swift
#Preview {
    ContentView()
        .environment(\.locale, Locale(identifier: "ja"))
}
```

### Export for Translation
1. Product > Export Localizations...
2. Share .xliff files with translators
3. Import translated .xliff files

## References

- [String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [Localization Guide](https://developer.apple.com/localization/)
- [Formatting Numbers and Dates](https://developer.apple.com/documentation/foundation/formatstyle)
