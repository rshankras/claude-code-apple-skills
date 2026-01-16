import Foundation

/// Type-safe localized strings.
///
/// Usage:
/// ```swift
/// Text(L10n.appName)
/// Text(L10n.Onboarding.welcomeTitle)
/// Text(L10n.itemsCount(5))
/// ```
///
/// Generated structure mirrors String Catalog organization.
/// Add new strings to String Catalog and update this file.
enum L10n {

    // MARK: - General

    /// App name
    static let appName = String(localized: "app_name", defaultValue: "MyApp")

    /// Common button titles
    static let ok = String(localized: "ok", defaultValue: "OK")
    static let cancel = String(localized: "cancel", defaultValue: "Cancel")
    static let done = String(localized: "done", defaultValue: "Done")
    static let save = String(localized: "save", defaultValue: "Save")
    static let delete = String(localized: "delete", defaultValue: "Delete")
    static let edit = String(localized: "edit", defaultValue: "Edit")
    static let close = String(localized: "close", defaultValue: "Close")
    static let retry = String(localized: "retry", defaultValue: "Retry")

    // MARK: - Onboarding

    enum Onboarding {
        static let welcomeTitle = String(localized: "onboarding.welcome.title",
                                         defaultValue: "Welcome")
        static let welcomeMessage = String(localized: "onboarding.welcome.message",
                                           defaultValue: "Thanks for downloading our app!")
        static let getStarted = String(localized: "onboarding.get_started",
                                       defaultValue: "Get Started")
        static let skip = String(localized: "onboarding.skip",
                                 defaultValue: "Skip")
        static let next = String(localized: "onboarding.next",
                                 defaultValue: "Next")
    }

    // MARK: - Settings

    enum Settings {
        static let title = String(localized: "settings.title",
                                  defaultValue: "Settings")
        static let appearance = String(localized: "settings.appearance",
                                       defaultValue: "Appearance")
        static let notifications = String(localized: "settings.notifications",
                                          defaultValue: "Notifications")
        static let privacy = String(localized: "settings.privacy",
                                    defaultValue: "Privacy")
        static let about = String(localized: "settings.about",
                                  defaultValue: "About")
        static let language = String(localized: "settings.language",
                                     defaultValue: "Language")
        static let version = String(localized: "settings.version",
                                    defaultValue: "Version")
    }

    // MARK: - Errors

    enum Error {
        static let genericTitle = String(localized: "error.generic.title",
                                         defaultValue: "Error")
        static let genericMessage = String(localized: "error.generic.message",
                                           defaultValue: "Something went wrong. Please try again.")
        static let networkTitle = String(localized: "error.network.title",
                                         defaultValue: "Network Error")
        static let networkMessage = String(localized: "error.network.message",
                                           defaultValue: "Please check your internet connection.")
        static let saveFailed = String(localized: "error.save_failed",
                                       defaultValue: "Failed to save. Please try again.")
        static let loadFailed = String(localized: "error.load_failed",
                                       defaultValue: "Failed to load data.")

        /// Custom error message with interpolation
        static func custom(_ message: String) -> String {
            String(localized: "error.custom \(message)",
                   defaultValue: "Error: \(message)")
        }
    }

    // MARK: - Plurals

    /// Plural-aware item count
    /// Requires plural variations in String Catalog:
    /// - zero: "No items"
    /// - one: "1 item"
    /// - other: "%lld items"
    static func itemsCount(_ count: Int) -> String {
        String(localized: "items.count \(count)",
               defaultValue: "\(count) items")
    }

    /// Plural-aware file count
    static func filesCount(_ count: Int) -> String {
        String(localized: "files.count \(count)",
               defaultValue: "\(count) files")
    }

    /// Days remaining
    static func daysRemaining(_ count: Int) -> String {
        String(localized: "days.remaining \(count)",
               defaultValue: "\(count) days remaining")
    }

    // MARK: - Interpolation Examples

    /// Greeting with name
    static func greeting(_ name: String) -> String {
        String(localized: "greeting \(name)",
               defaultValue: "Hello, \(name)!")
    }

    /// Welcome back message
    static func welcomeBack(_ name: String) -> String {
        String(localized: "welcome_back \(name)",
               defaultValue: "Welcome back, \(name)")
    }

    /// Last updated timestamp
    static func lastUpdated(_ date: Date) -> String {
        String(localized: "last_updated \(date, format: .dateTime)",
               defaultValue: "Last updated: \(date.formatted())")
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let closeButton = String(localized: "accessibility.close_button",
                                        defaultValue: "Close")
        static let backButton = String(localized: "accessibility.back_button",
                                       defaultValue: "Go back")
        static let menuButton = String(localized: "accessibility.menu_button",
                                       defaultValue: "Open menu")
        static let favoriteButton = String(localized: "accessibility.favorite_button",
                                           defaultValue: "Add to favorites")
        static let shareButton = String(localized: "accessibility.share_button",
                                        defaultValue: "Share")

        static func selected(_ isSelected: Bool) -> String {
            isSelected
                ? String(localized: "accessibility.selected", defaultValue: "Selected")
                : String(localized: "accessibility.not_selected", defaultValue: "Not selected")
        }
    }
}

// MARK: - String Catalog Key Reference

/*
 Add these keys to your Localizable.xcstrings file:

 General:
 - app_name
 - ok
 - cancel
 - done
 - save
 - delete
 - edit
 - close
 - retry

 Onboarding:
 - onboarding.welcome.title
 - onboarding.welcome.message
 - onboarding.get_started
 - onboarding.skip
 - onboarding.next

 Settings:
 - settings.title
 - settings.appearance
 - settings.notifications
 - settings.privacy
 - settings.about
 - settings.language
 - settings.version

 Errors:
 - error.generic.title
 - error.generic.message
 - error.network.title
 - error.network.message
 - error.save_failed
 - error.load_failed
 - error.custom %@

 Plurals (with variations):
 - items.count %lld
 - files.count %lld
 - days.remaining %lld

 Interpolation:
 - greeting %@
 - welcome_back %@
 - last_updated %@

 Accessibility:
 - accessibility.close_button
 - accessibility.back_button
 - accessibility.menu_button
 - accessibility.favorite_button
 - accessibility.share_button
 - accessibility.selected
 - accessibility.not_selected
 */
