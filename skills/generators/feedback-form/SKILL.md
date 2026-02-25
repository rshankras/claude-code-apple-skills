---
name: feedback-form
description: Generates an in-app feedback collection form with category selection, text input, optional screenshot attachment, device diagnostics, and smart routing — directing happy users to App Store reviews and unhappy users to support. Use when user wants feedback, bug reports, feature requests, or contact support forms.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Feedback Form Generator

Generate a production in-app feedback form with category selection, sentiment-based rating, optional screenshot attachment, device diagnostics collection, and smart routing that funnels satisfied users to the App Store review prompt and dissatisfied users to a support channel.

## When This Skill Activates

Use this skill when the user:
- Asks to "add a feedback form" or "feedback form"
- Wants "in-app feedback" or "user feedback" collection
- Mentions "bug report form" or "feature request" form
- Asks about "contact support" from within the app
- Wants "feedback collection" with categories or screenshots
- Asks to "route users to App Store review" based on sentiment

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing feedback or support code:
```
Glob: **/*Feedback*.swift, **/*Support*.swift, **/*BugReport*.swift, **/*ContactForm*.swift
Grep: "MFMailComposeViewController" or "FeedbackForm" or "SKStoreReviewController"
```

If third-party feedback SDK found (Instabug, UserVoice, Zendesk):
- Ask if user wants to replace or keep it
- If keeping, don't generate — advise on best practices instead

### 3. Framework Detection
Check for MessageUI availability:
```
Grep: "import MessageUI" or "MFMailCompose"
```
Note: MessageUI is iOS-only. macOS uses `NSSharingService` or direct webhook delivery.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Feedback categories?** (multi-select)
   - Bug Report
   - Feature Request
   - General Feedback
   - Praise
   - Other
   - All of the above — recommended

2. **Delivery method?**
   - Email (via MFMailComposeViewController / NSSharingService)
   - Webhook (POST to a URL endpoint)
   - Both — recommended

3. **Include screenshot capture?**
   - Yes — recommended (capture current screen + annotation overlay)
   - No

4. **Include device diagnostics?**
   - Yes — recommended (device model, OS, app version, disk, memory)
   - No

5. **Sentiment routing?**
   - Yes — recommended (rating >= 4 suggests App Store review, rating <= 2 routes to support)
   - No (all feedback goes through the same channel)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `FeedbackCategory.swift` — Enum with SF Symbol icons and display names
2. `FeedbackEntry.swift` — Data model for a feedback submission
3. `DeviceDiagnostics.swift` — Collects device and app info

### Step 3: Create UI Files
4. `FeedbackFormView.swift` — SwiftUI form with sentiment, category, message, screenshots

### Step 4: Create Delivery Files
5. `FeedbackSubmitter.swift` — Protocol + EmailFeedbackSubmitter + WebhookFeedbackSubmitter

### Step 5: Create Optional Files
Based on configuration:
- `ScreenshotCapture.swift` — If screenshot capture selected

### Step 6: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/Feedback/`
- If `App/` exists -> `App/Feedback/`
- Otherwise -> `Feedback/`

## Output Format

After generation, provide:

### Files Created
```
Feedback/
├── FeedbackCategory.swift       # Category enum with icons
├── FeedbackEntry.swift          # Feedback data model
├── DeviceDiagnostics.swift      # Device info collector
├── FeedbackFormView.swift       # SwiftUI form view
├── FeedbackSubmitter.swift      # Email + webhook delivery
└── ScreenshotCapture.swift      # Screen capture (optional)
```

### Integration Steps

**Present the feedback form from any view:**
```swift
@State private var showFeedback = false

Button("Send Feedback") {
    showFeedback = true
}
.sheet(isPresented: $showFeedback) {
    FeedbackFormView()
}
```

**In a settings screen:**
```swift
Form {
    Section("Support") {
        Button {
            showFeedback = true
        } label: {
            Label("Send Feedback", systemImage: "bubble.left.and.text.bubble.right")
        }
    }
}
.sheet(isPresented: $showFeedback) {
    FeedbackFormView()
}
```

**With a pre-selected category (e.g., from a help menu):**
```swift
FeedbackFormView(initialCategory: .bugReport)
```

### Testing

```swift
@Test
func feedbackEntryEncodesCorrectly() throws {
    let entry = FeedbackEntry(
        category: .bugReport,
        message: "App crashes when tapping save",
        rating: 2,
        screenshots: [],
        deviceInfo: DeviceDiagnostics.collect(),
        appVersion: "1.2.3",
        timestamp: Date()
    )

    let data = try JSONEncoder().encode(entry)
    let decoded = try JSONDecoder().decode(FeedbackEntry.self, from: data)
    #expect(decoded.category == .bugReport)
    #expect(decoded.rating == 2)
}

@Test
func webhookSubmitterSendsCorrectPayload() async throws {
    let mockSession = MockURLSession()
    let submitter = WebhookFeedbackSubmitter(
        url: URL(string: "https://example.com/feedback")!,
        session: mockSession
    )

    let entry = FeedbackEntry(
        category: .featureRequest,
        message: "Dark mode support please",
        rating: 4,
        screenshots: [],
        deviceInfo: DeviceDiagnostics.collect(),
        appVersion: "1.0.0",
        timestamp: Date()
    )

    try await submitter.submit(entry)
    #expect(mockSession.lastRequest?.httpMethod == "POST")
    #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
}

@Test
func sentimentRoutingDirectsHighRatingToReview() {
    let entry = FeedbackEntry(
        category: .praise,
        message: "Love this app!",
        rating: 5,
        screenshots: [],
        deviceInfo: DeviceDiagnostics.collect(),
        appVersion: "1.0.0",
        timestamp: Date()
    )

    #expect(entry.suggestsAppStoreReview) // rating >= 4
}
```

## Common Patterns

### Open feedback form from a menu bar app
```swift
Button {
    showFeedback = true
    NSApp.activate(ignoringOtherApps: true)
} label: {
    Label("Send Feedback", systemImage: "envelope")
}
.sheet(isPresented: $showFeedback) {
    FeedbackFormView()
}
```

### Submit feedback with a screenshot attachment
```swift
let screenshot = try await ScreenshotCapture.captureCurrentWindow()
let entry = FeedbackEntry(
    category: .bugReport,
    message: "Layout is broken on this screen",
    rating: 1,
    screenshots: [screenshot],
    deviceInfo: DeviceDiagnostics.collect(),
    appVersion: Bundle.main.appVersion,
    timestamp: Date()
)
try await submitter.submit(entry)
```

### Route by sentiment after submission
```swift
if entry.suggestsAppStoreReview {
    // Happy user — ask for App Store review
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene)
    }
} else if entry.suggestsSupportFollowUp {
    // Unhappy user — show support confirmation
    showSupportConfirmation = true
}
```

## Gotchas

- **MFMailComposeViewController requires a mail account**: Check `MFMailComposeViewController.canSendMail()` before presenting. Fall back to webhook or `mailto:` URL if unavailable.
- **Screenshot privacy**: Consider blurring or redacting sensitive data (passwords, financial info) before attaching. Use `UITextField.isSecureTextEntry` areas as a guide.
- **Attachment size limits for email**: Email attachments are typically limited to 10-25 MB. Compress screenshots to JPEG and resize if needed. Webhook delivery is more reliable for large attachments.
- **Offline submission queuing**: If the device is offline when feedback is submitted, queue the entry to disk and retry when connectivity is restored. Use `NWPathMonitor` to detect network changes.
- **App Store review prompt limits**: `SKStoreReviewController.requestReview()` is rate-limited by the system (typically 3 times per 365-day period). Don't rely on it always appearing.
- **macOS has no MFMailComposeViewController**: Use `NSSharingService(named: .composeEmail)` or prefer webhook delivery on macOS.

## References

- **templates.md** — All production Swift templates
- Related: `generators/review-prompt` — App Store review prompt timing and strategy
