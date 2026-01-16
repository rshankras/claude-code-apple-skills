import SwiftUI

// MARK: - Locale Preview Modifiers

#if DEBUG

/// Preview modifier for testing localization.
///
/// Usage:
/// ```swift
/// #Preview {
///     ContentView()
///         .localePreview("es")
/// }
/// ```
extension View {
    /// Preview in a specific locale.
    func localePreview(_ identifier: String) -> some View {
        let locale = Locale(identifier: identifier)
        let isRTL = Locale.characterDirection(forLanguage: identifier) == .rightToLeft

        return self
            .environment(\.locale, locale)
            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
    }

    /// Preview in multiple locales at once.
    func multiLocalePreview(
        _ identifiers: [String] = ["en", "es", "de", "ja", "ar"]
    ) -> some View {
        ForEach(identifiers, id: \.self) { identifier in
            self.localePreview(identifier)
                .previewDisplayName(
                    Locale.current.localizedString(forIdentifier: identifier) ?? identifier
                )
        }
    }
}

// MARK: - Preview Providers

/// Preview wrapper for testing localization in different locales.
///
/// Usage:
/// ```swift
/// #Preview {
///     LocalizedPreview {
///         ContentView()
///     }
/// }
/// ```
struct LocalizedPreview<Content: View>: View {
    let content: Content
    let locales: [String]

    init(
        locales: [String] = ["en", "es", "ja", "ar"],
        @ViewBuilder content: () -> Content
    ) {
        self.locales = locales
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(locales, id: \.self) { locale in
                    Section(header: Text(localeName(for: locale))) {
                        content
                            .environment(\.locale, Locale(identifier: locale))
                            .environment(
                                \.layoutDirection,
                                 isRTL(locale) ? .rightToLeft : .leftToRight
                            )
                    }
                }
            }
        }
    }

    private func localeName(for identifier: String) -> String {
        let native = Locale(identifier: identifier)
            .localizedString(forLanguageCode: identifier) ?? identifier
        let english = Locale(identifier: "en")
            .localizedString(forLanguageCode: identifier) ?? identifier
        return "\(native) (\(english))"
    }

    private func isRTL(_ identifier: String) -> Bool {
        Locale.characterDirection(forLanguage: identifier) == .rightToLeft
    }
}

// MARK: - RTL Preview

/// Preview specifically for testing RTL layout.
///
/// Usage:
/// ```swift
/// #Preview {
///     RTLPreview {
///         MyView()
///     }
/// }
/// ```
struct RTLPreview<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text("LTR (English)")
                    .font(.caption)
                    .padding(.bottom, 4)
                content
                    .environment(\.locale, Locale(identifier: "en"))
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack {
                Text("RTL (Arabic)")
                    .font(.caption)
                    .padding(.bottom, 4)
                content
                    .environment(\.locale, Locale(identifier: "ar"))
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Dynamic Type + Localization Preview

/// Preview for testing localization with different Dynamic Type sizes.
///
/// Usage:
/// ```swift
/// #Preview {
///     DynamicTypeLocalePreview(locale: "de") {
///         MyView()
///     }
/// }
/// ```
struct DynamicTypeLocalePreview<Content: View>: View {
    let content: Content
    let locale: String
    let sizes: [DynamicTypeSize]

    init(
        locale: String = "en",
        sizes: [DynamicTypeSize] = [.small, .large, .xxxLarge],
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.locale = locale
        self.sizes = sizes
    }

    var body: some View {
        ForEach(sizes, id: \.self) { size in
            content
                .environment(\.locale, Locale(identifier: locale))
                .environment(\.dynamicTypeSize, size)
                .previewDisplayName("\(locale) - \(String(describing: size))")
        }
    }
}

// MARK: - Common Locale Sets

/// Predefined sets of locales for different testing scenarios.
enum LocalePresets {
    /// Common Western languages
    static let western = ["en", "es", "fr", "de", "it", "pt"]

    /// Asian languages
    static let asian = ["ja", "zh-Hans", "zh-Hant", "ko"]

    /// RTL languages
    static let rtl = ["ar", "he", "fa"]

    /// Comprehensive set
    static let comprehensive = western + asian + rtl

    /// Quick test set (one from each category)
    static let quick = ["en", "es", "ja", "ar"]

    /// Languages with long words (for layout testing)
    static let longWords = ["de", "fi", "hu"]
}

// MARK: - Example Previews

#Preview("Quick Locale Test") {
    VStack(spacing: 20) {
        Text("Hello, World!")
        Text(Date(), format: .dateTime)
        Text(1234.56, format: .currency(code: "USD"))
    }
    .multiLocalePreview(LocalePresets.quick)
}

#Preview("RTL Comparison") {
    RTLPreview {
        HStack {
            Image(systemName: "arrow.right")
            Text("Direction Test")
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
    }
}

#endif
