---
name: announcement-banner
description: Generates an in-app announcement banner system with remote configuration, scheduling, deep link actions, and dismiss tracking. Use when user wants in-app banners, promotional notices, maintenance alerts, or contextual announcements.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Announcement Banner Generator

Generate a configurable in-app announcement/banner system that displays contextual messages (maintenance alerts, new feature highlights, promotions) from remote config or local definitions. Supports dismissal, deep link actions, and scheduling.

## When This Skill Activates

Use this skill when the user:
- Asks to "add announcement banner" or "in-app banner"
- Wants "app announcement" or "notification banner"
- Mentions "promotional banner" or "promo banner"
- Asks about "maintenance notice" or "maintenance alert"
- Wants "in-app messaging" or "contextual banners"
- Asks to "show announcements" or "display alerts to users"
- Mentions "feature highlight banner" or "what's new banner"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing banner/toast code:
```
Glob: **/*Banner*.swift, **/*Announcement*.swift, **/*Toast*.swift, **/*InAppMessage*.swift
Grep: "AnnouncementBanner" or "InAppBanner" or "ToastView" or "BannerView"
```

If third-party library found (Firebase In-App Messaging, Braze, Intercom):
- Ask if user wants to replace or keep it
- If keeping, don't generate — advise on integration patterns instead

### 3. Deep Linking Detection
Check for existing deep linking setup:
```
Grep: "deepLink" or "DeepLink" or "universalLink" or "openURL" or "onOpenURL"
```

If deep linking exists, integrate with it. If not, generate standalone action handling.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Banner position?**
   - Top (slides in from top) — recommended for alerts
   - Bottom (slides in from bottom)
   - Floating (centered overlay with dimmed background)

2. **Content source?**
   - Local only (hardcoded announcements in code)
   - Remote JSON (fetch from server endpoint)
   - Both (remote with local fallbacks) — recommended

3. **Action type?**
   - Deep link (navigate to in-app screen)
   - URL (open in Safari/SFSafariViewController)
   - Dismiss only (informational, no action button)
   - All of the above — recommended

4. **Include scheduling (start/end dates)?**
   - Yes (time-limited announcements with date ranges) — recommended
   - No (always-active until dismissed)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `Announcement.swift` — Model with style, action, priority, scheduling
2. `AnnouncementManager.swift` — @Observable manager: loads, filters, tracks dismissals
3. `AnnouncementProvider.swift` — Protocol + local/remote implementations with caching

### Step 3: Create UI Files
4. `AnnouncementBannerView.swift` — SwiftUI banner with style-aware colors and animations
5. `AnnouncementBannerModifier.swift` — ViewModifier for overlay placement and action routing

### Step 4: Create Optional Files
Based on configuration:
- `AnnouncementScheduler.swift` — If scheduling selected (date range filtering, timezone handling)

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/AnnouncementBanner/`
- If `App/` exists -> `App/AnnouncementBanner/`
- Otherwise -> `AnnouncementBanner/`

## Output Format

After generation, provide:

### Files Created
```
AnnouncementBanner/
├── Announcement.swift              # Model with style, action, priority
├── AnnouncementManager.swift       # Observable manager with dismiss tracking
├── AnnouncementProvider.swift      # Protocol + local/remote providers
├── AnnouncementBannerView.swift    # SwiftUI banner view
├── AnnouncementBannerModifier.swift# ViewModifier for overlay + actions
└── AnnouncementScheduler.swift     # Date range filtering (optional)
```

### Integration Steps

**Add banner overlay to root view:**
```swift
// In your root ContentView or NavigationStack
ContentView()
    .announcementBanner()
```

**With custom position:**
```swift
ContentView()
    .announcementBanner(position: .bottom)
```

**With deep link action handler:**
```swift
ContentView()
    .announcementBanner { action in
        switch action {
        case .deepLink(let destination):
            router.navigate(to: destination)
        case .url(let url):
            openURL(url)
        case .dismiss:
            break
        }
    }
```

**Define local announcements:**
```swift
let provider = LocalAnnouncementProvider(announcements: [
    Announcement(
        id: "maintenance-2024",
        title: "Scheduled Maintenance",
        message: "We'll be performing maintenance on Saturday 9-11 AM EST.",
        style: .warning,
        action: .dismiss,
        priority: 10,
        startDate: maintenanceStart,
        endDate: maintenanceEnd
    ),
    Announcement(
        id: "new-feature-photos",
        title: "New: Photo Library",
        message: "Check out our new photo library with AI-powered search!",
        style: .promotion,
        action: .deepLink("app://features/photos"),
        priority: 5,
        isDismissible: true
    )
])
```

**Fetch from remote config:**
```swift
let provider = RemoteAnnouncementProvider(
    url: URL(string: "https://api.example.com/announcements")!,
    cacheDuration: 3600  // 1 hour
)
```

### Testing

```swift
@Test
func dismissedAnnouncementsAreHidden() async throws {
    let manager = AnnouncementManager(
        provider: MockAnnouncementProvider(announcements: [testAnnouncement]),
        dismissalStore: InMemoryDismissalStore()
    )

    await manager.loadAnnouncements()
    #expect(manager.activeAnnouncement != nil)

    manager.dismiss(testAnnouncement)
    #expect(manager.activeAnnouncement == nil)
}

@Test
func highestPriorityAnnouncementShownFirst() async throws {
    let lowPriority = Announcement(id: "low", title: "Low", message: "...", style: .info, priority: 1)
    let highPriority = Announcement(id: "high", title: "High", message: "...", style: .warning, priority: 10)
    let manager = AnnouncementManager(
        provider: MockAnnouncementProvider(announcements: [lowPriority, highPriority])
    )

    await manager.loadAnnouncements()
    #expect(manager.activeAnnouncement?.id == "high")
}

@Test
func expiredAnnouncementsAreFiltered() async throws {
    let expired = Announcement(
        id: "expired",
        title: "Old",
        message: "...",
        style: .info,
        endDate: Date.distantPast
    )
    let manager = AnnouncementManager(
        provider: MockAnnouncementProvider(announcements: [expired])
    )

    await manager.loadAnnouncements()
    #expect(manager.activeAnnouncement == nil)
}
```

## Common Patterns

### Show Maintenance Banner
```swift
Announcement(
    id: "maintenance-\(date)",
    title: "Scheduled Maintenance",
    message: "Service will be unavailable Saturday 2-4 AM EST.",
    style: .warning,
    action: .url(URL(string: "https://status.example.com")!),
    priority: 100,  // High priority overrides other banners
    startDate: Calendar.current.date(byAdding: .day, value: -1, to: maintenanceDate)!,
    endDate: maintenanceEndDate,
    isDismissible: false  // Can't dismiss maintenance warnings
)
```

### Promote New Feature
```swift
Announcement(
    id: "feature-v2.5-darkmode",
    title: "Dark Mode is Here!",
    message: "Try our new dark mode in Settings.",
    style: .promotion,
    action: .deepLink("app://settings/appearance"),
    priority: 5,
    isDismissible: true
)
```

### Time-Limited Promotion
```swift
Announcement(
    id: "promo-summer-2024",
    title: "Summer Sale - 40% Off!",
    message: "Upgrade to Pro at our lowest price ever.",
    style: .promotion,
    action: .deepLink("app://subscription/upgrade"),
    priority: 8,
    startDate: promoStart,
    endDate: promoEnd,
    isDismissible: true,
    targetAudience: .freeUsers
)
```

## Gotchas

1. **Banner stacking** — Never show multiple banners simultaneously. Use priority to determine which single banner to display. Queue others and show the next one after dismissal.
2. **Don't cover critical UI** — Ensure the banner doesn't overlap navigation bars, tab bars, or interactive elements. Use safe area insets.
3. **Respect user dismissal** — Persist dismissed announcement IDs so they don't reappear after app relaunch. Use UserDefaults or a lightweight store.
4. **Remote config caching** — Cache fetched announcements to avoid network requests on every app launch. Honor cache duration but allow force-refresh.
5. **Date/timezone handling** — Always use UTC for start/end dates in remote config. Convert to local timezone only for display purposes.
6. **Accessibility** — Announce banner appearance with `AccessibilityNotification.Announcement`. Ensure dismiss button has proper label.
7. **Animation interruption** — If a user navigates away mid-animation, ensure the banner state resets properly. Use `.task` tied to view lifecycle.

## References

- **templates.md** — All production Swift templates
- Related: `generators/deep-linking` — Deep link routing integration
- Related: `generators/whats-new` — What's new screen for feature highlights
