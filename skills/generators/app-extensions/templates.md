# App Extensions Code Templates

Production-ready Swift templates for app extension infrastructure. All code targets iOS 16+ / macOS 13+ and follows Apple's extension architecture guidelines.

## ShareViewController.swift

```swift
import UIKit
import UniformTypeIdentifiers
import os

/// Share extension view controller that accepts content from other apps.
///
/// Handles URLs, text, images, and files shared via the system share sheet.
/// Processes the shared content and optionally saves it to the main app
/// via App Groups.
///
/// ## Supported Content Types
///
/// Configure supported types in Info.plist under NSExtensionActivationRule.
/// This controller handles:
/// - URLs (web links, deep links)
/// - Plain text and rich text
/// - Images (JPEG, PNG, HEIC)
/// - Files (PDF, documents)
///
/// ## Info.plist Configuration
///
/// ```xml
/// <key>NSExtension</key>
/// <dict>
///     <key>NSExtensionPointIdentifier</key>
///     <string>com.apple.share-services</string>
///     <key>NSExtensionPrincipalClass</key>
///     <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
///     <key>NSExtensionActivationRule</key>
///     <dict>
///         <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
///         <integer>1</integer>
///         <key>NSExtensionActivationSupportsText</key>
///         <true/>
///         <key>NSExtensionActivationSupportsImageWithMaxCount</key>
///         <integer>5</integer>
///     </dict>
/// </dict>
/// ```
class ShareViewController: UIViewController {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app.share",
        category: "ShareExtension"
    )

    // MARK: - UI Elements

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Save to App"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Processing..."
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Save"
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Shared Content

    private var sharedURLs: [URL] = []
    private var sharedTexts: [String] = []
    private var sharedImages: [Data] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        handleSharedContent()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(cancelButton)
        containerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 250),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
    }

    // MARK: - Content Handling

    private func handleSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            complete(with: .noData)
            return
        }

        let group = DispatchGroup()

        for item in extensionItems {
            for provider in item.attachments ?? [] {
                // Handle URLs
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, error in
                        defer { group.leave() }
                        if let url = item as? URL {
                            self?.sharedURLs.append(url)
                        }
                    }
                }

                // Handle plain text
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, error in
                        defer { group.leave() }
                        if let text = item as? String {
                            self?.sharedTexts.append(text)
                        }
                    }
                }

                // Handle images
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] item, error in
                        defer { group.leave() }
                        if let imageURL = item as? URL,
                           let imageData = try? Data(contentsOf: imageURL) {
                            self?.sharedImages.append(imageData)
                        } else if let image = item as? UIImage,
                                  let imageData = image.jpegData(compressionQuality: 0.8) {
                            self?.sharedImages.append(imageData)
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.updateStatusLabel()
        }
    }

    private func updateStatusLabel() {
        var parts: [String] = []
        if !sharedURLs.isEmpty { parts.append("\(sharedURLs.count) URL(s)") }
        if !sharedTexts.isEmpty { parts.append("\(sharedTexts.count) text item(s)") }
        if !sharedImages.isEmpty { parts.append("\(sharedImages.count) image(s)") }

        if parts.isEmpty {
            statusLabel.text = "No supported content found"
            saveButton.isEnabled = false
        } else {
            statusLabel.text = "Ready to save: " + parts.joined(separator: ", ")
            saveButton.isEnabled = true
        }
    }

    // MARK: - Actions

    @objc private func saveAction() {
        // Save shared content via App Groups
        let shared = SharedDataManager.shared

        if let firstURL = sharedURLs.first {
            shared.set(firstURL.absoluteString, forKey: "lastSharedURL")
        }

        if let firstText = sharedTexts.first {
            shared.set(firstText, forKey: "lastSharedText")
        }

        logger.info("Saved shared content: \(self.sharedURLs.count) URLs, \(self.sharedTexts.count) texts, \(self.sharedImages.count) images")
        complete(with: .saved)
    }

    @objc private func cancelAction() {
        complete(with: .cancelled)
    }

    // MARK: - Completion

    private enum CompletionReason {
        case saved, cancelled, noData
    }

    private func complete(with reason: CompletionReason) {
        switch reason {
        case .saved, .noData:
            extensionContext?.completeRequest(returningItems: nil)
        case .cancelled:
            extensionContext?.cancelRequest(withError: NSError(
                domain: NSCocoaErrorDomain,
                code: NSUserCancelledError
            ))
        }
    }
}
```

## ActionViewController.swift

```swift
import UIKit
import UniformTypeIdentifiers
import os

/// Action extension that manipulates content in-place.
///
/// Action extensions receive content from a host app, allow the user
/// to manipulate it, and return the modified content back to the host.
///
/// ## Info.plist Configuration
///
/// ```xml
/// <key>NSExtension</key>
/// <dict>
///     <key>NSExtensionPointIdentifier</key>
///     <string>com.apple.ui-services</string>
///     <key>NSExtensionPrincipalClass</key>
///     <string>$(PRODUCT_MODULE_NAME).ActionViewController</string>
///     <key>NSExtensionActivationRule</key>
///     <dict>
///         <key>NSExtensionActivationSupportsText</key>
///         <true/>
///         <key>NSExtensionActivationSupportsImageWithMaxCount</key>
///         <integer>1</integer>
///     </dict>
/// </dict>
/// ```
class ActionViewController: UIViewController {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app.action",
        category: "ActionExtension"
    )

    private var inputText: String?
    private var inputImage: UIImage?

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.font = .preferredFont(forTextStyle: .body)
        tv.isEditable = true
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadInputContent()
    }

    // MARK: - UI Setup

    private func setupUI() {
        title = "Edit Content"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelAction)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneAction)
        )

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }

    // MARK: - Content Loading

    private func loadInputContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        for item in extensionItems {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, error in
                        guard let text = item as? String else { return }
                        DispatchQueue.main.async {
                            self?.inputText = text
                            self?.textView.text = text
                        }
                    }
                    return
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func doneAction() {
        // Return modified content to the host app
        let modifiedText = textView.text ?? ""

        let returnItem = NSExtensionItem()
        let textData = NSItemProvider(item: modifiedText as NSString, typeIdentifier: UTType.plainText.identifier)
        returnItem.attachments = [textData]

        extensionContext?.completeRequest(returningItems: [returnItem])
    }

    @objc private func cancelAction() {
        extensionContext?.cancelRequest(withError: NSError(
            domain: NSCocoaErrorDomain,
            code: NSUserCancelledError
        ))
    }
}
```

## KeyboardViewController.swift

```swift
import UIKit

/// Custom keyboard extension using UIInputViewController.
///
/// Provides a custom keyboard interface that users can install via
/// Settings > General > Keyboard > Keyboards > Add New Keyboard.
///
/// ## Memory Constraints
///
/// Keyboard extensions are limited to approximately 48 MB of memory.
/// Keep the view hierarchy simple and avoid loading large resources.
///
/// ## Network Access
///
/// By default, keyboard extensions have no network access.
/// The user must enable "Allow Full Access" in Settings for network
/// requests to work. Check `hasFullAccess` before making network calls.
///
/// ## Info.plist Configuration
///
/// ```xml
/// <key>NSExtension</key>
/// <dict>
///     <key>NSExtensionPointIdentifier</key>
///     <string>com.apple.keyboard-service</string>
///     <key>NSExtensionPrincipalClass</key>
///     <string>$(PRODUCT_MODULE_NAME).KeyboardViewController</string>
///     <key>NSExtensionAttributes</key>
///     <dict>
///         <key>IsASCIICapable</key>
///         <false/>
///         <key>PrefersRightToLeft</key>
///         <false/>
///         <key>PrimaryLanguage</key>
///         <string>en-US</string>
///         <key>RequestsOpenAccess</key>
///         <false/>
///     </dict>
/// </dict>
/// ```
class KeyboardViewController: UIInputViewController {

    /// Standard keyboard layout rows.
    private let keyboardRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"],
    ]

    private var isShifted = false

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Keyboard height constraint
    }

    // MARK: - Setup

    private func setupKeyboard() {
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
        ])

        // Add letter rows
        for row in keyboardRows {
            let rowStack = createRowStack(keys: row)
            stackView.addArrangedSubview(rowStack)
        }

        // Add bottom row with special keys
        let bottomRow = createBottomRow()
        stackView.addArrangedSubview(bottomRow)
    }

    private func createRowStack(keys: [String]) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually

        for key in keys {
            let button = createKeyButton(title: key)
            button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }

        return stack
    }

    private func createBottomRow() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually

        // Globe button (switch keyboard)
        let globeButton = createKeyButton(title: "globe", isSystem: true)
        globeButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        stack.addArrangedSubview(globeButton)

        // Space bar
        let spaceButton = createKeyButton(title: "space")
        spaceButton.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        stack.addArrangedSubview(spaceButton)
        stack.addArrangedSubview(spaceButton) // Double width by adding twice -- in production use constraints

        // Backspace
        let backspaceButton = createKeyButton(title: "delete.left", isSystem: true)
        backspaceButton.addTarget(self, action: #selector(backspaceTapped), for: .touchUpInside)
        stack.addArrangedSubview(backspaceButton)

        // Return
        let returnButton = createKeyButton(title: "Return")
        returnButton.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        stack.addArrangedSubview(returnButton)

        return stack
    }

    private func createKeyButton(title: String, isSystem: Bool = false) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        config.baseBackgroundColor = .secondarySystemBackground
        config.baseForegroundColor = .label

        if isSystem {
            config.image = UIImage(systemName: title)
        } else {
            config.title = title
        }

        let button = UIButton(configuration: config)
        button.titleLabel?.font = .systemFont(ofSize: 22)
        return button
    }

    // MARK: - Key Actions

    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.titleLabel?.text else { return }
        let character = isShifted ? title.uppercased() : title.lowercased()
        textDocumentProxy.insertText(character)

        // Auto-lowercase after typing
        if isShifted {
            isShifted = false
        }
    }

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
    }

    @objc private func backspaceTapped() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
    }

    // MARK: - Text Input

    override func textWillChange(_ textInput: (any UITextInput)?) {
        // Called before text changes in the document
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        // Called after text changes -- update key appearance if needed
    }
}
```

## SafariWebExtensionHandler.swift

```swift
import SafariServices
import os

/// Native message handler for Safari Web Extension.
///
/// Receives messages from the web extension's JavaScript code and
/// responds with native functionality. Bridges the gap between
/// browser content scripts and native Swift capabilities.
///
/// ## Message Flow
///
/// 1. Content script calls `browser.runtime.sendNativeMessage()`
/// 2. System delivers the message to this handler
/// 3. Handler processes the message and returns a response
/// 4. Content script receives the response in its callback
///
/// ## JavaScript (content.js)
///
/// ```javascript
/// browser.runtime.sendNativeMessage(
///     "application.id",
///     { action: "getContent", url: window.location.href },
///     function(response) {
///         console.log("Received:", response);
///     }
/// );
/// ```
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app.safari",
        category: "SafariExtension"
    )

    func beginRequest(with context: NSExtensionContext) {
        guard let message = extractMessage(from: context) else {
            context.completeRequest(returningItems: nil)
            return
        }

        logger.info("Received message from web extension: \(message)")

        let action = message["action"] as? String ?? "unknown"

        // Route to appropriate handler
        let response: [String: Any]
        switch action {
        case "getContent":
            response = handleGetContent(message: message)
        case "saveContent":
            response = handleSaveContent(message: message)
        case "getSettings":
            response = handleGetSettings()
        default:
            response = ["error": "Unknown action: \(action)"]
        }

        // Send response back to JavaScript
        let responseItem = NSExtensionItem()
        responseItem.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [responseItem])
    }

    // MARK: - Message Extraction

    private func extractMessage(from context: NSExtensionContext) -> [String: Any]? {
        guard let item = context.inputItems.first as? NSExtensionItem else { return nil }
        return item.userInfo?[SFExtensionMessageKey] as? [String: Any]
    }

    // MARK: - Action Handlers

    private func handleGetContent(message: [String: Any]) -> [String: Any] {
        let url = message["url"] as? String ?? ""

        // TODO: Process the URL or return stored data
        return [
            "status": "success",
            "url": url,
            "data": "Processed content for \(url)"
        ]
    }

    private func handleSaveContent(message: [String: Any]) -> [String: Any] {
        guard let content = message["content"] as? String,
              let url = message["url"] as? String else {
            return ["status": "error", "message": "Missing content or URL"]
        }

        // Save via App Groups for main app access
        let shared = SharedDataManager.shared
        shared.set(content, forKey: "safari_saved_content")
        shared.set(url, forKey: "safari_saved_url")

        logger.info("Saved content from \(url)")
        return ["status": "success", "message": "Content saved"]
    }

    private func handleGetSettings() -> [String: Any] {
        let shared = SharedDataManager.shared
        return [
            "status": "success",
            "settings": [
                "enabled": shared.bool(forKey: "extensionEnabled"),
                "theme": shared.string(forKey: "extensionTheme") ?? "auto"
            ]
        ]
    }
}
```

## SharedDataManager.swift

```swift
import Foundation
import os

/// Manages data sharing between the main app and its extensions via App Groups.
///
/// Uses a shared `UserDefaults` suite and a shared file container
/// to pass data between the app and its extensions (Share, Action,
/// Keyboard, Safari, Widgets).
///
/// ## Setup Requirements
///
/// 1. Enable "App Groups" capability on both the main app and extension targets
/// 2. Add the same group identifier to both (e.g., `group.com.yourapp.shared`)
/// 3. Match the `suiteName` constant below to your group identifier
///
/// ## Usage
///
/// ```swift
/// let shared = SharedDataManager.shared
///
/// // Write from extension
/// shared.set("https://example.com", forKey: "lastSharedURL")
///
/// // Read from main app
/// let url = shared.string(forKey: "lastSharedURL")
///
/// // Share files
/// let fileURL = shared.sharedContainerURL?.appendingPathComponent("data.json")
/// ```
final class SharedDataManager: Sendable {
    static let shared = SharedDataManager()

    /// The App Group identifier. Must match the identifier configured
    /// in both the app and extension entitlements.
    private let suiteName = "group.com.yourapp.shared"

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app",
        category: "SharedData"
    )

    // MARK: - UserDefaults Access

    /// Shared UserDefaults accessible by both the app and extensions.
    ///
    /// Returns nil if the App Group is not properly configured.
    var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// Set a value in shared UserDefaults.
    func set(_ value: Any?, forKey key: String) {
        guard let defaults else {
            logger.error("Failed to access shared UserDefaults. Check App Group configuration.")
            return
        }
        defaults.set(value, forKey: key)
    }

    /// Get a string from shared UserDefaults.
    func string(forKey key: String) -> String? {
        defaults?.string(forKey: key)
    }

    /// Get a boolean from shared UserDefaults.
    func bool(forKey key: String) -> Bool {
        defaults?.bool(forKey: key) ?? false
    }

    /// Get data from shared UserDefaults.
    func data(forKey key: String) -> Data? {
        defaults?.data(forKey: key)
    }

    /// Remove a value from shared UserDefaults.
    func remove(forKey key: String) {
        defaults?.removeObject(forKey: key)
    }

    // MARK: - File Container Access

    /// URL to the shared file container.
    ///
    /// Use this for sharing files (images, documents, databases) between
    /// the app and extensions. Returns nil if App Group is not configured.
    var sharedContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: suiteName
        )
    }

    /// Write data to a file in the shared container.
    ///
    /// - Parameters:
    ///   - data: The data to write.
    ///   - filename: The filename (e.g., "shared-data.json").
    /// - Returns: The URL of the written file, or nil on failure.
    @discardableResult
    func writeFile(_ data: Data, named filename: String) -> URL? {
        guard let containerURL = sharedContainerURL else {
            logger.error("Shared container not available. Check App Group configuration.")
            return nil
        }

        let fileURL = containerURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            logger.error("Failed to write shared file: \(error.localizedDescription)")
            return nil
        }
    }

    /// Read data from a file in the shared container.
    ///
    /// - Parameter filename: The filename to read.
    /// - Returns: The file data, or nil if the file doesn't exist.
    func readFile(named filename: String) -> Data? {
        guard let containerURL = sharedContainerURL else {
            logger.error("Shared container not available. Check App Group configuration.")
            return nil
        }

        let fileURL = containerURL.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    /// Delete a file from the shared container.
    func deleteFile(named filename: String) {
        guard let containerURL = sharedContainerURL else { return }
        let fileURL = containerURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Codable Convenience

    /// Save a Codable object to shared UserDefaults.
    func saveCodable<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            logger.error("Failed to encode \(T.self) for shared storage")
            return
        }
        set(data, forKey: key)
    }

    /// Load a Codable object from shared UserDefaults.
    func loadCodable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Keychain Sharing

    /// Save a string to the shared Keychain.
    ///
    /// Requires Keychain Sharing capability with matching access group.
    func saveToKeychain(value: String, forKey key: String, accessGroup: String? = nil) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Load a string from the shared Keychain.
    func loadFromKeychain(forKey key: String, accessGroup: String? = nil) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else { return nil }

        return String(data: data, encoding: .utf8)
    }
}
```
