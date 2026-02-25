---
name: account-deletion
description: Generates an Apple-compliant account deletion flow with multi-step confirmation UI, optional data export, configurable grace period, Keychain cleanup, and server-side deletion request. Use when user needs account deletion, right-to-delete, or Apple App Review compliance for account removal.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Account Deletion Generator

Generate a production account deletion flow compliant with Apple's App Store requirement (effective June 30, 2022) that any app offering account creation must also offer account deletion from within the app. Includes multi-step confirmation UI, optional data export, configurable grace period, Keychain cleanup, and Sign in with Apple token revocation.

## When This Skill Activates

Use this skill when the user:
- Asks to "add account deletion" or "delete account"
- Wants to "remove account" or implement "account removal"
- Mentions "right to delete" or "user data deletion"
- Asks about "Apple account deletion requirement"
- Needs App Store compliance for account management
- Wants to implement GDPR/privacy right-to-erasure

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Existing Auth/Account Code
Search for existing account management:
```
Glob: **/*Auth*.swift, **/*Account*.swift, **/*User*.swift, **/*Profile*.swift
Grep: "ASAuthorizationAppleIDProvider" or "SignInWithApple" or "Keychain" or "deleteAccount"
```

If existing deletion flow found:
- Ask if user wants to replace or enhance it
- If enhancing, integrate with existing auth architecture

### 3. Keychain Usage Detection
```
Grep: "SecItemAdd" or "SecItemDelete" or "SecItemCopyMatching" or "KeychainWrapper" or "keychain"
```

If Keychain usage found, ensure cleanup covers all stored items.

### 4. CloudKit / Server Sync Detection
```
Grep: "CKContainer" or "CloudKit" or "CKRecord" or "NSPersistentCloudKitContainer"
Glob: **/*CloudKit*.swift, **/*Sync*.swift
```

If CloudKit or server sync found, include remote data cleanup steps.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Deletion type?**
   - Immediate — account deleted right away after confirmation
   - Grace period — account scheduled for deletion, user can cancel

2. **Grace period duration?** (if grace period selected)
   - 7 days
   - 14 days — recommended
   - 30 days

3. **Include data export before deletion?**
   - Yes — generate DataExportService with JSON/ZIP archive and ShareLink
   - No — skip data export

4. **Server-side API call needed?**
   - Yes — generate server deletion request with configurable endpoint
   - No — local-only deletion (Keychain, UserDefaults, SwiftData/CoreData, files)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `AccountDeletionManager.swift` — @Observable orchestrator for the full deletion lifecycle
2. `DeletionConfirmationView.swift` — Multi-step confirmation UI with NavigationStack
3. `KeychainCleanup.swift` — Utility to remove all app Keychain items

### Step 3: Create Optional Files
Based on configuration:
- `DataExportService.swift` — If data export selected
- `DeletionGracePeriodView.swift` — If grace period selected
- `SignInWithAppleRevocation.swift` — If SIWA detected in project

### Step 4: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/AccountDeletion/`
- If `App/` exists -> `App/AccountDeletion/`
- Otherwise -> `AccountDeletion/`

## Output Format

After generation, provide:

### Files Created
```
AccountDeletion/
├── AccountDeletionManager.swift      # Orchestrator for deletion lifecycle
├── DeletionConfirmationView.swift    # Multi-step confirmation UI
├── KeychainCleanup.swift             # Keychain item cleanup
├── DataExportService.swift           # Data export before deletion (optional)
├── DeletionGracePeriodView.swift     # Grace period countdown UI (optional)
└── SignInWithAppleRevocation.swift    # SIWA token revocation (optional)
```

### Integration Steps

**Add to Settings or Account screen:**
```swift
// In your Settings or Account view
struct AccountSettingsView: View {
    @State private var showDeletionFlow = false

    var body: some View {
        Form {
            // ... other settings ...

            Section {
                Button(role: .destructive) {
                    showDeletionFlow = true
                } label: {
                    Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                }
            } footer: {
                Text("Permanently removes your account and all associated data.")
            }
        }
        .sheet(isPresented: $showDeletionFlow) {
            DeletionConfirmationView()
        }
    }
}
```

**With grace period (check on app launch):**
```swift
@main
struct MyApp: App {
    @State private var deletionManager = AccountDeletionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(deletionManager)
                .task {
                    await deletionManager.checkPendingDeletion()
                }
        }
    }
}
```

**With data export:**
```swift
// User can export before deleting
DeletionConfirmationView()
    .environment(DataExportService())
```

### Testing

```swift
@Test
func deletionFlowCompletesSuccessfully() async throws {
    let manager = AccountDeletionManager(
        serverClient: MockDeletionClient(),
        keychainCleanup: MockKeychainCleanup()
    )

    try await manager.confirmWithReauthentication()
    try await manager.executeDeletion()

    #expect(manager.deletionState == .completed)
}

@Test
func gracePeriodCancellation() async throws {
    let manager = AccountDeletionManager()

    try await manager.scheduleDeletion(gracePeriodDays: 14)
    #expect(manager.scheduledDeletionDate != nil)

    try await manager.cancelScheduledDeletion()
    #expect(manager.deletionState == .none)
    #expect(manager.scheduledDeletionDate == nil)
}

@Test
func keychainItemsRemovedOnDeletion() async throws {
    let cleanup = KeychainCleanup()
    // Store a test item
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "test-account",
        kSecValueData as String: Data("secret".utf8)
    ]
    SecItemAdd(query as CFDictionary, nil)

    // Delete all items
    try cleanup.removeAllItems()

    // Verify removal
    let searchQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "test-account",
        kSecReturnData as String: true
    ]
    let status = SecItemCopyMatching(searchQuery as CFDictionary, nil)
    #expect(status == errSecItemNotFound)
}

@Test
func dataExportGeneratesArchive() async throws {
    let exportService = DataExportService()
    let archiveURL = try await exportService.exportAllUserData()

    #expect(FileManager.default.fileExists(atPath: archiveURL.path))

    // Cleanup
    try FileManager.default.removeItem(at: archiveURL)
}
```

## Common Patterns

### Initiate Deletion from Settings
Account deletion must be accessible from within the app — typically in Settings > Account. Apple will reject apps that only offer deletion via website or email.

### Confirm with Password or Biometric
Re-authenticate the user before deletion to prevent accidental or unauthorized account removal. Use LocalAuthentication for biometric or prompt for password.

### Export Data Before Deletion
Offer users the ability to download their data before the account is removed. This is a privacy best practice and builds user trust.

### Schedule Deletion with Grace Period
Instead of immediate deletion, schedule it for 7-30 days out. Allow users to cancel during this window. Many users delete accounts impulsively and appreciate the recovery option.

## Gotchas

- **Apple requires in-app deletion** — App Review will reject apps where account deletion is only available via website, email, or contacting support. The option must be accessible from within the app itself.
- **Keychain items persist after app uninstall** — You must explicitly call `SecItemDelete` for all item classes (generic password, internet password, certificate, key, identity) during account deletion.
- **Sign in with Apple token revocation** — If your app supports Sign in with Apple, you must revoke the user's token via Apple's REST API (`https://appleid.apple.com/auth/revoke`). Failure to do so means Apple still considers the account linked.
- **CloudKit data cleanup** — CloudKit private database records are tied to the user's iCloud account, not your app. You cannot delete them on behalf of the user. Document this limitation and delete any shared/public records your app created.
- **Subscription cancellation guidance** — Account deletion does not automatically cancel active subscriptions. Display a warning and link to Settings > Subscriptions so users can cancel before deletion.
- **UserDefaults and app group data** — Remember to clean `UserDefaults.standard` and any shared app group containers (`UserDefaults(suiteName:)`).
- **SwiftData / CoreData cleanup** — Delete all model containers and persistent stores, not just individual records.

## References

- **templates.md** — All production Swift templates
- Related: `generators/auth-flow` — Authentication flow generation
- Related: `generators/persistence-setup` — Data persistence that needs cleanup
- Related: `generators/settings-screen` — Settings screen where deletion is placed
- Related: `generators/cloudkit-sync` — CloudKit data that needs cleanup consideration
