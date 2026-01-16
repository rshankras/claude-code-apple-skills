import Foundation
import SwiftData
import CloudKit

/// CloudKit configuration for iCloud sync.
///
/// Prerequisites:
/// 1. Enable iCloud capability in Xcode
/// 2. Check "CloudKit" service
/// 3. Add container identifier
/// 4. Add required entitlements
///
/// Usage:
/// ```swift
/// let container = try CloudKitConfiguration.createContainer(
///     for: [Item.self],
///     containerIdentifier: "iCloud.com.yourcompany.yourapp"
/// )
/// ```
enum CloudKitConfiguration {

    // MARK: - Container Identifier

    /// Your CloudKit container identifier.
    /// Format: iCloud.com.yourcompany.yourapp
    ///
    /// Must match:
    /// - Xcode capability configuration
    /// - Entitlements file
    /// - CloudKit Dashboard
    static let containerIdentifier = "iCloud.com.yourcompany.yourapp"

    // MARK: - Container Creation

    /// Create a ModelContainer with CloudKit sync enabled.
    @MainActor
    static func createContainer(
        for modelTypes: [any PersistentModel.Type],
        containerIdentifier: String = CloudKitConfiguration.containerIdentifier
    ) throws -> ModelContainer {
        let schema = Schema(modelTypes)

        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(containerIdentifier)
        )

        return try ModelContainer(
            for: schema,
            configurations: configuration
        )
    }

    /// Create a ModelContainer with automatic CloudKit database selection.
    /// Uses private database for user-specific data.
    @MainActor
    static func createAutoContainer(
        for modelTypes: [any PersistentModel.Type]
    ) throws -> ModelContainer {
        let schema = Schema(modelTypes)

        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )

        return try ModelContainer(
            for: schema,
            configurations: configuration
        )
    }

    // MARK: - Account Status

    /// Check if the user is signed into iCloud.
    static func checkAccountStatus() async throws -> CKAccountStatus {
        try await CKContainer.default().accountStatus()
    }

    /// Check if CloudKit is available for this user.
    static func isCloudKitAvailable() async -> Bool {
        do {
            let status = try await checkAccountStatus()
            return status == .available
        } catch {
            return false
        }
    }
}

// MARK: - Container Identifier Validation

extension CloudKitConfiguration {

    /// Validate that the container identifier is properly formatted.
    static func validateContainerIdentifier(_ identifier: String) -> Bool {
        // Must start with "iCloud."
        guard identifier.hasPrefix("iCloud.") else { return false }

        // Must have a valid bundle ID format after "iCloud."
        let bundleIDPart = String(identifier.dropFirst("iCloud.".count))
        let bundleIDRegex = #"^[a-zA-Z][a-zA-Z0-9\-\.]*[a-zA-Z0-9]$"#

        return bundleIDPart.range(of: bundleIDRegex, options: .regularExpression) != nil
    }
}

// MARK: - Entitlements Reference

/*
 Required entitlements for iCloud sync:

 ```xml
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
     <key>com.apple.developer.icloud-container-identifiers</key>
     <array>
         <string>iCloud.com.yourcompany.yourapp</string>
     </array>
     <key>com.apple.developer.icloud-services</key>
     <array>
         <string>CloudKit</string>
     </array>
 </dict>
 </plist>
 ```

 For background sync, also add to Info.plist:
 ```xml
 <key>UIBackgroundModes</key>
 <array>
     <string>remote-notification</string>
 </array>
 ```
 */
