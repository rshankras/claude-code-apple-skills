# TipKit Code Templates

## Tips.configure() Setup

### Basic Configuration

```swift
import TipKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? Tips.configure([
                        .displayFrequency(.daily),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
```

### Configuration with Testing Support

```swift
import TipKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    #if DEBUG
                    // Reset tips on every launch during development
                    try? Tips.resetDatastore()
                    #endif

                    try? Tips.configure([
                        .displayFrequency(.daily),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
```

### Display Frequency Options

```swift
// Tips can show as soon as eligible
.displayFrequency(.immediate)

// At most one tip per hour
.displayFrequency(.hourly)

// At most one tip per day (recommended for most apps)
.displayFrequency(.daily)

// At most one tip per week
.displayFrequency(.weekly)

// At most one tip per month
.displayFrequency(.monthly)
```

### DataStore Location Options

```swift
// Default location managed by the system
.datastoreLocation(.applicationDefault)

// Custom URL (useful for isolating test data)
.datastoreLocation(.url(FileManager.default
    .urls(for: .cachesDirectory, in: .userDomainMask)
    .first!
    .appending(path: "tips-store")))
```

---

## Tip Protocol Conformance

### Minimal Tip (Title Only)

```swift
import TipKit

struct SearchTip: Tip {
    var title: Text {
        Text("Try searching")
    }
}
```

### Tip with Title and Message

```swift
import TipKit

struct SearchTip: Tip {
    var title: Text {
        Text("Search your library")
    }

    var message: Text? {
        Text("Quickly find any item by name, tag, or date.")
    }
}
```

### Tip with Title, Message, and Image

```swift
import TipKit

struct SearchTip: Tip {
    var title: Text {
        Text("Search your library")
    }

    var message: Text? {
        Text("Quickly find any item by name, tag, or date.")
    }

    var image: Image? {
        Image(systemName: "magnifyingglass")
    }
}
```

### Tip with Actions

```swift
import TipKit

struct UpgradeTip: Tip {
    var title: Text {
        Text("Unlock more features")
    }

    var message: Text? {
        Text("Upgrade to Pro for unlimited access.")
    }

    var actions: [Action] {
        Action(id: "learn-more", title: "Learn More")
        Action(id: "dismiss", title: "Not Now")
    }
}
```

Handling actions in the view:

```swift
TipView(upgradeTip) { action in
    if action.id == "learn-more" {
        showUpgradeSheet = true
    }
    // Tip auto-dismisses after any action tap
}
```

---

## Parameter-Based Rules

### Boolean Parameter

```swift
import TipKit

struct AdvancedSearchTip: Tip {
    @Parameter
    static var hasUsedBasicSearch: Bool = false

    var title: Text {
        Text("Try advanced search")
    }

    var message: Text? {
        Text("Use filters to narrow your results.")
    }

    var rules: [Rule] {
        #Rule(Self.$hasUsedBasicSearch) { $0 == true }
    }
}
```

Setting the parameter from elsewhere in the app:

```swift
func onBasicSearchPerformed() {
    AdvancedSearchTip.hasUsedBasicSearch = true
}
```

### Numeric Parameter

```swift
import TipKit

struct PowerUserTip: Tip {
    @Parameter
    static var itemsCreated: Int = 0

    var title: Text {
        Text("You are on a roll")
    }

    var message: Text? {
        Text("Try using templates to create items even faster.")
    }

    var rules: [Rule] {
        #Rule(Self.$itemsCreated) { $0 >= 5 }
    }
}
```

Incrementing the parameter:

```swift
func onItemCreated() {
    PowerUserTip.itemsCreated += 1
}
```

---

## Event-Based Rules

### Basic Event Rule

```swift
import TipKit

struct FilterTip: Tip {
    static let listViewed = Tips.Event(id: "listViewed")

    var title: Text {
        Text("Filter your results")
    }

    var message: Text? {
        Text("Tap the filter icon to narrow down what you see.")
    }

    var rules: [Rule] {
        #Rule(Self.listViewed) { $0.donations.count >= 3 }
    }
}
```

Donating the event:

```swift
struct ListView: View {
    var body: some View {
        List { /* ... */ }
            .onAppear {
                FilterTip.listViewed.donate()
            }
    }
}
```

### Event with Associated Value

```swift
import TipKit

struct ShareTip: Tip {
    static let photoViewed = Tips.Event(id: "photoViewed")

    var title: Text {
        Text("Share this photo")
    }

    var message: Text? {
        Text("Tap the share button to send this to friends.")
    }

    var rules: [Rule] {
        #Rule(Self.photoViewed) {
            $0.donations.count >= 2
        }
    }
}
```

---

## Combining Multiple Rules

### Parameter + Event

```swift
import TipKit

struct ExportTip: Tip {
    @Parameter
    static var hasCreatedDocument: Bool = false

    static let documentEdited = Tips.Event(id: "documentEdited")

    var title: Text {
        Text("Export your work")
    }

    var message: Text? {
        Text("Tap Export to save as PDF or share with others.")
    }

    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }

    var rules: [Rule] {
        #Rule(Self.$hasCreatedDocument) { $0 == true }
        #Rule(Self.documentEdited) { $0.donations.count >= 2 }
    }
}
```

All rules must be satisfied (logical AND) for the tip to become eligible.

---

## Tip Options

### MaxDisplayCount

```swift
import TipKit

struct SwipeToDeleteTip: Tip {
    var title: Text {
        Text("Swipe to delete")
    }

    var message: Text? {
        Text("Swipe left on any item to delete it.")
    }

    // Tip will be shown at most 3 times across app sessions
    var options: [TipOption] {
        MaxDisplayCount(3)
    }
}
```

### IgnoresDisplayFrequency

```swift
import TipKit

struct CriticalTip: Tip {
    var title: Text {
        Text("Important update")
    }

    var message: Text? {
        Text("Your data has been migrated. Review your settings.")
    }

    // This tip ignores the global .displayFrequency setting
    var options: [TipOption] {
        IgnoresDisplayFrequency(true)
    }
}
```

### Combining Options

```swift
var options: [TipOption] {
    MaxDisplayCount(5)
    IgnoresDisplayFrequency(true)
}
```

---

## Centralized Event Definitions

When multiple tips share events, centralize them:

```swift
// TipEvents.swift
import TipKit

enum TipEvents {
    static let appLaunched = Tips.Event(id: "appLaunched")
    static let listViewed = Tips.Event(id: "listViewed")
    static let itemCreated = Tips.Event(id: "itemCreated")
    static let searchPerformed = Tips.Event(id: "searchPerformed")
}
```

Reference from tip structs:

```swift
struct FilterTip: Tip {
    var title: Text {
        Text("Filter your results")
    }

    var rules: [Rule] {
        #Rule(TipEvents.listViewed) { $0.donations.count >= 3 }
    }
}
```

---

## Inline Tips (TipView)

### Basic Inline Tip

```swift
import SwiftUI
import TipKit

struct SearchView: View {
    let searchTip = SearchTip()

    var body: some View {
        VStack {
            TipView(searchTip)
            SearchBar()
            ResultsList()
        }
    }
}
```

### Inline Tip with Custom Arrow Direction

```swift
TipView(searchTip, arrowEdge: .bottom)
```

### Inline Tip with Action Handling

```swift
TipView(upgradeTip) { action in
    switch action.id {
    case "learn-more":
        showUpgradeSheet = true
    case "dismiss":
        break // Tip auto-dismisses
    default:
        break
    }
}
```

---

## Popover Tips

### Basic Popover

```swift
import SwiftUI
import TipKit

struct ToolbarView: View {
    let filterTip = FilterTip()

    var body: some View {
        HStack {
            Spacer()
            Button("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                showFilters.toggle()
            }
            .popoverTip(filterTip)
        }
    }
}
```

### Popover with Custom Arrow Direction

```swift
Button("Sort") {
    // action
}
.popoverTip(sortTip, arrowEdge: .top)
```

---

## Tip Invalidation

### Invalidate on Action Performed

```swift
struct SearchView: View {
    let searchTip = SearchTip()

    var body: some View {
        VStack {
            TipView(searchTip)
            SearchBar(onSearch: { query in
                performSearch(query)
                searchTip.invalidate(reason: .actionPerformed)
            })
        }
    }
}
```

### Invalidation Reasons

```swift
// User performed the action the tip describes
tip.invalidate(reason: .actionPerformed)

// Tip was shown enough times (reached MaxDisplayCount)
// This happens automatically -- you do not call this manually

// User closed the tip via the X button
// This happens automatically when the user taps dismiss
```

### Invalidate from Elsewhere

Hold a reference to the same tip instance, or define a static method:

```swift
struct SearchTip: Tip {
    var title: Text {
        Text("Try searching")
    }

    // Call this when the feature is discovered
    static func markAsDiscovered() {
        // Create a temporary instance to invalidate all displays of this tip
        SearchTip().invalidate(reason: .actionPerformed)
    }
}
```

---

## TipGroup (Ordered Tips)

### Basic TipGroup

```swift
import SwiftUI
import TipKit

struct OnboardingTipsView: View {
    @State var tipGroup = TipGroup(.ordered) {
        CreateItemTip()
        EditItemTip()
        ShareItemTip()
    }

    var body: some View {
        VStack {
            // Only the current tip in the group is shown
            TipView(tipGroup.currentTip!)
        }
    }
}
```

### TipGroup with Priority Ordering

```swift
// .ordered: tips appear in the order listed, one at a time
// Each tip must be dismissed or invalidated before the next appears
@State var tipGroup = TipGroup(.ordered) {
    WelcomeTip()       // Shows first
    SearchTip()        // Shows second, after WelcomeTip is dismissed
    FilterTip()        // Shows third
}
```

### TipGroup in a View

```swift
struct ContentView: View {
    @State var tipGroup = TipGroup(.ordered) {
        WelcomeTip()
        SearchTip()
        FilterTip()
    }

    var body: some View {
        VStack {
            if let currentTip = tipGroup.currentTip {
                TipView(currentTip)
            }

            MainContent()
        }
    }
}
```

---

## Testing Utilities

### TipsConfiguration Helper

```swift
// TipsConfiguration.swift
import TipKit

enum TipsConfiguration {
    /// Call once at app startup
    static func configure(frequency: Tips.ConfigurationOption.DisplayFrequency = .daily) {
        try? Tips.configure([
            .displayFrequency(frequency),
            .datastoreLocation(.applicationDefault)
        ])
    }

    /// Show all tips regardless of rules and frequency (debug only)
    static func showAllForTesting() {
        Tips.showAllTipsForTesting()
    }

    /// Show only specific tips for testing
    static func showForTesting(_ tips: [any Tip.Type]) {
        Tips.showTipsForTesting(tips)
    }

    /// Reset all tip state (debug only)
    static func resetAll() {
        try? Tips.resetDatastore()
    }
}
```

### Debug Menu Integration

```swift
#if DEBUG
struct TipsDebugMenu: View {
    var body: some View {
        Section("Tips (Debug)") {
            Button("Reset All Tips") {
                TipsConfiguration.resetAll()
            }
            Button("Show All Tips") {
                TipsConfiguration.showAllForTesting()
            }
            Button("Show Search Tip Only") {
                TipsConfiguration.showForTesting([SearchTip.self])
            }
        }
    }
}
#endif
```

### SwiftUI Preview Support

```swift
#Preview {
    SearchView()
        .task {
            try? Tips.resetDatastore()
            Tips.showAllTipsForTesting()
            try? Tips.configure()
        }
}
```

---

## Complete Example: Feature Discovery Flow

This example shows a complete tip setup for an app with search, filter, and export features.

### Tip Definitions

```swift
// SearchTip.swift
import TipKit

struct SearchTip: Tip {
    static let appOpened = Tips.Event(id: "appOpened")

    var title: Text {
        Text("Search your items")
    }

    var message: Text? {
        Text("Use the search bar to quickly find what you need.")
    }

    var image: Image? {
        Image(systemName: "magnifyingglass")
    }

    var rules: [Rule] {
        #Rule(Self.appOpened) { $0.donations.count >= 2 }
    }
}
```

```swift
// FilterTip.swift
import TipKit

struct FilterTip: Tip {
    @Parameter
    static var hasSearched: Bool = false

    var title: Text {
        Text("Narrow your results")
    }

    var message: Text? {
        Text("Tap the filter icon to show only what matters.")
    }

    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease.circle")
    }

    var rules: [Rule] {
        #Rule(Self.$hasSearched) { $0 == true }
    }

    var options: [TipOption] {
        MaxDisplayCount(3)
    }
}
```

```swift
// ExportTip.swift
import TipKit

struct ExportTip: Tip {
    @Parameter
    static var hasFilteredResults: Bool = false

    static let itemViewed = Tips.Event(id: "itemViewed")

    var title: Text {
        Text("Export your results")
    }

    var message: Text? {
        Text("Share or save your filtered results as a PDF.")
    }

    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }

    var rules: [Rule] {
        #Rule(Self.$hasFilteredResults) { $0 == true }
        #Rule(Self.itemViewed) { $0.donations.count >= 3 }
    }
}
```

### View Integration

```swift
// ContentView.swift
import SwiftUI
import TipKit

struct ContentView: View {
    let searchTip = SearchTip()
    let filterTip = FilterTip()
    let exportTip = ExportTip()

    @State private var searchText = ""
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            VStack {
                // Inline tip above search bar
                TipView(searchTip)

                SearchBar(text: $searchText, onCommit: {
                    searchTip.invalidate(reason: .actionPerformed)
                    FilterTip.hasSearched = true
                })

                ResultsList(searchText: searchText)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        showFilters.toggle()
                        filterTip.invalidate(reason: .actionPerformed)
                        ExportTip.hasFilteredResults = true
                    }
                    .popoverTip(filterTip)
                }

                ToolbarItem(placement: .secondaryAction) {
                    Button("Export", systemImage: "square.and.arrow.up") {
                        exportResults()
                        exportTip.invalidate(reason: .actionPerformed)
                    }
                    .popoverTip(exportTip)
                }
            }
            .onAppear {
                SearchTip.appOpened.donate()
            }
        }
    }

    private func exportResults() {
        // Export logic
    }
}
```

### App Entry Point

```swift
// MyApp.swift
import SwiftUI
import TipKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    #if DEBUG
                    try? Tips.resetDatastore()
                    #endif

                    try? Tips.configure([
                        .displayFrequency(.daily),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
```

---

## Patterns: Good vs Bad

### Tip Definition

```swift
// ✅ Good: One tip per file, clear naming, meaningful image
struct SearchTip: Tip {
    var title: Text { Text("Search your library") }
    var message: Text? { Text("Find items by name, tag, or date.") }
    var image: Image? { Image(systemName: "magnifyingglass") }
}
```

```swift
// ❌ Bad: Multiple tips crammed into one file with vague names
struct Tips {
    struct Tip1: Tip { /* ... */ }
    struct Tip2: Tip { /* ... */ }
    struct Tip3: Tip { /* ... */ }
}
```

### Tips.configure() Placement

```swift
// ✅ Good: Configure early in the app lifecycle
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? Tips.configure([
                        .displayFrequency(.daily),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}
```

```swift
// ❌ Bad: Configure inside a deeply nested view (may run too late or multiple times)
struct SomeNestedView: View {
    var body: some View {
        Text("Hello")
            .task {
                try? Tips.configure()  // Too late, may miss early tips
            }
    }
}
```

### Display Frequency

```swift
// ✅ Good: Use .daily or .weekly for production to avoid overwhelming users
.displayFrequency(.daily)
```

```swift
// ❌ Bad: Using .immediate in production -- users see every tip at once
.displayFrequency(.immediate)
```

### Tip Invalidation

```swift
// ✅ Good: Invalidate the tip instance that is currently displayed
struct SearchView: View {
    let searchTip = SearchTip()

    var body: some View {
        VStack {
            TipView(searchTip)
            Button("Search") {
                performSearch()
                searchTip.invalidate(reason: .actionPerformed)
            }
        }
    }
}
```

```swift
// ❌ Bad: Creating a new instance to invalidate (does not affect the displayed tip)
Button("Search") {
    performSearch()
    SearchTip().invalidate(reason: .actionPerformed)  // New instance -- no effect on displayed tip
}
```

### Parameter Updates

```swift
// ✅ Good: Update parameter at the point where the condition becomes true
func onSearchPerformed() {
    FilterTip.hasSearched = true
}
```

```swift
// ❌ Bad: Setting the parameter in the tip's own init (defeats the purpose of rules)
struct FilterTip: Tip {
    @Parameter static var hasSearched: Bool = false
    init() { Self.hasSearched = true }  // Always true -- rule is pointless
}
```

### Event Donation

```swift
// ✅ Good: Donate events at natural user interaction points
List(items) { item in
    ItemRow(item: item)
}
.onAppear {
    FilterTip.listViewed.donate()
}
```

```swift
// ❌ Bad: Donating events in a timer or background task (inflates counts artificially)
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    FilterTip.listViewed.donate()  // Fires every second -- meaningless
}
```

### TipGroup Usage

```swift
// ✅ Good: Use TipGroup when tips should appear in a logical learning sequence
@State var onboardingTips = TipGroup(.ordered) {
    WelcomeTip()
    CreateItemTip()
    ShareItemTip()
}

var body: some View {
    VStack {
        if let tip = onboardingTips.currentTip {
            TipView(tip)
        }
        MainContent()
    }
}
```

```swift
// ❌ Bad: Manually tracking tip ordering with state variables
@State private var currentTipIndex = 0
// Then manually showing/hiding tips based on index -- fragile and error-prone
```
