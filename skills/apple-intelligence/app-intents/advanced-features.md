# Advanced Features

Intent modes, interactive snippets, visual intelligence integration, onscreen entities, multiple choice, property macros, and Swift package support. These features require iOS 26 / macOS 26 unless noted otherwise.

## Intent Modes

Control whether your intent runs in the background or needs to come to the foreground. Available in iOS 26 / macOS 26.

### supportedModes Property

```swift
struct SyncDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync Data"

    // Runs entirely in the background -- no UI needed
    var supportedModes: IntentModes { .background }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await DataService.shared.syncAll()
        return .result(dialog: "Data synced successfully.")
    }
}
```

### Mode Options

| Mode | Behavior |
|------|----------|
| `.background` | Runs without showing the app. Best for data operations. |
| `.foreground(.immediate)` | Opens the app immediately before `perform()` runs. |
| `.foreground(.dynamic)` | Starts in background, may move to foreground during execution. |
| `.foreground(.deferred)` | Starts in background, opens app after `perform()` completes. |

### Dynamic Foreground Transition

Start in background, move to foreground only if needed:

```swift
struct EditDocumentIntent: AppIntent {
    static var title: LocalizedStringResource = "Edit Document"

    @Parameter(title: "Document")
    var document: DocumentEntity

    // Start background, but can transition to foreground
    var supportedModes: IntentModes { .foreground(.dynamic) }

    func perform() async throws -> some IntentResult {
        let doc = try await DocumentStore.shared.fetch(id: document.id)

        if doc.requiresAuthentication {
            // Move to foreground to show auth UI
            try await continueInForeground(alwaysConfirm: true)
            await MainActor.run {
                AppState.shared.showAuthThenEdit(document: doc)
            }
        } else {
            // Stay in background
            try await DocumentStore.shared.openForEditing(doc)
        }

        return .result()
    }
}
```

### continueInForeground

Call this inside `perform()` to transition from background to foreground:

```swift
// Transition to foreground, ask user to confirm
try await continueInForeground(alwaysConfirm: true)

// Transition to foreground without confirmation
try await continueInForeground(alwaysConfirm: false)
```

If the user declines (when `alwaysConfirm: true`), the method throws `needsToContinueInForegroundError()`.

### needsToContinueInForegroundError

When an intent absolutely must run in the foreground but was started in the background, throw this error to prompt the user:

```swift
func perform() async throws -> some IntentResult {
    guard canRunInBackground else {
        throw needsToContinueInForegroundError(
            "This action requires the app to be open."
        )
    }
    // background work
    return .result()
}
```

### Patterns

```swift
// ✅ Good -- background intent for data work
var supportedModes: IntentModes { .background }

// ✅ Good -- immediate foreground for camera/AR features
var supportedModes: IntentModes { .foreground(.immediate) }

// ✅ Good -- dynamic for intents that might need UI
var supportedModes: IntentModes { .foreground(.dynamic) }

// ❌ Wrong -- using openAppWhenRun instead of supportedModes (legacy approach)
static var openAppWhenRun = true
```

Note: `openAppWhenRun` still works on older OS versions but `supportedModes` is the preferred API on iOS 26+.

## Multiple Choice API

Present a set of options and let the user pick one. Available in iOS 26 / macOS 26.

### requestChoice(between:dialog:)

```swift
struct PickPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Pick Playlist"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let playlists = await MusicStore.shared.allPlaylists()

        let options = playlists.map { playlist in
            IntentChoiceOption(
                value: playlist.id,
                title: "\(playlist.name)",
                subtitle: "\(playlist.trackCount) tracks"
            )
        }

        let chosen = try await requestChoice(
            between: options,
            dialog: "Which playlist would you like to play?"
        )

        await MusicPlayer.shared.play(playlistID: chosen)
        let playlist = playlists.first { $0.id == chosen }
        return .result(dialog: "Now playing \(playlist?.name ?? "playlist").")
    }
}
```

### IntentChoiceOption

Each option has a value, title, and optional subtitle/image:

```swift
// Text only
IntentChoiceOption(
    value: item.id,
    title: "\(item.name)"
)

// With subtitle
IntentChoiceOption(
    value: item.id,
    title: "\(item.name)",
    subtitle: "\(item.detail)"
)

// With system image
IntentChoiceOption(
    value: item.id,
    title: "\(item.name)",
    image: .init(systemName: "star.fill")
)
```

### Patterns

```swift
// ✅ Good -- descriptive dialog, meaningful option labels
let chosen = try await requestChoice(
    between: options,
    dialog: "Which account should I transfer from?"
)

// ❌ Wrong -- vague dialog, no context
let chosen = try await requestChoice(
    between: options,
    dialog: "Pick one"
)
```

## Property Macros

New property macros for smarter entity data handling. Available in iOS 26 / macOS 26.

### @ComputedProperty

Computed from a source of truth. The system knows this value is derived and does not store it independently:

```swift
struct OrderEntity: AppEntity {
    var id: String
    var items: [OrderItem]

    @ComputedProperty(title: "Total")
    var total: Double {
        items.reduce(0) { $0 + $1.price * Double($1.quantity) }
    }

    @ComputedProperty(title: "Item Count")
    var itemCount: Int {
        items.count
    }

    // ...display representations and defaultQuery
}
```

### @DeferredProperty

Expensive to compute, fetched on demand only when the system actually needs the value:

```swift
struct PhotoEntity: AppEntity {
    var id: String
    var name: String

    @DeferredProperty(title: "File Size")
    var fileSize: Int  // Fetched lazily, only when requested

    @DeferredProperty(title: "Dimensions")
    var dimensions: String  // e.g., "3024x4032"

    // ...display representations and defaultQuery
}
```

The system calls a separate fetch only when these properties are needed, avoiding upfront cost for listing entities.

## Interactive Snippets

Show SwiftUI views in Siri results. Static snippets display information; interactive snippets accept user actions.

### Static Snippets

Return a view from `perform()` using `.result(view:)`:

```swift
struct WeatherIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Weather"

    @Parameter(title: "City")
    var city: String

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let weather = try await WeatherService.shared.fetch(city: city)

        return .result(view: WeatherSnippetView(weather: weather))
    }
}

struct WeatherSnippetView: View {
    let weather: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: weather.symbolName)
                    .font(.title)
                Text(weather.city)
                    .font(.headline)
            }
            Text("\(weather.temperature, format: .number)°")
                .font(.system(size: 48, weight: .thin))
            Text(weather.condition)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

### Interactive Snippets with SnippetIntent

Use `SnippetIntent` to add buttons and controls that trigger follow-up actions:

```swift
// The main intent shows the snippet
struct ShowTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Timer"

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let timer = await TimerService.shared.activeTimer()
        return .result(view: TimerSnippetView(timer: timer))
    }
}

// A snippet intent handles button taps within the snippet
struct PauseTimerSnippetIntent: AppIntent, SnippetIntent {
    static var title: LocalizedStringResource = "Pause Timer"

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let timer = await TimerService.shared.pauseActive()
        // Return updated snippet view
        return .result(view: TimerSnippetView(timer: timer))
    }
}

struct ResumeTimerSnippetIntent: AppIntent, SnippetIntent {
    static var title: LocalizedStringResource = "Resume Timer"

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let timer = await TimerService.shared.resumeActive()
        return .result(view: TimerSnippetView(timer: timer))
    }
}

// The snippet view uses IntentButton to trigger snippet intents
struct TimerSnippetView: View {
    let timer: TimerState

    var body: some View {
        VStack(spacing: 12) {
            Text(timer.remaining, format: .time(pattern: .minuteSecond))
                .font(.system(size: 36, weight: .medium, design: .monospaced))

            HStack(spacing: 16) {
                if timer.isRunning {
                    IntentButton(intent: PauseTimerSnippetIntent()) {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.bordered)
                } else {
                    IntentButton(intent: ResumeTimerSnippetIntent()) {
                        Label("Resume", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}
```

Key rules for interactive snippets:
- Button actions must use `SnippetIntent` conformance, not plain `AppIntent`
- Use `IntentButton` (not `Button`) to trigger intents from within snippet views
- The snippet intent's `perform()` returns an updated snippet view
- Keep snippet views lightweight; they run in a constrained environment

### Patterns

```swift
// ✅ Good -- SnippetIntent for interactive buttons
struct LikeSnippetIntent: AppIntent, SnippetIntent {
    static var title: LocalizedStringResource = "Like"
    // ...
}

// ❌ Wrong -- plain AppIntent used in a snippet button
struct LikeIntent: AppIntent {  // Missing SnippetIntent conformance
    static var title: LocalizedStringResource = "Like"
    // IntentButton with this intent will not work in a snippet
}

// ✅ Good -- IntentButton in snippet view
IntentButton(intent: LikeSnippetIntent()) {
    Label("Like", systemImage: "heart")
}

// ❌ Wrong -- regular Button in snippet view (cannot trigger intents)
Button("Like") {
    // This closure runs in the snippet process, not your app
}
```

## Visual Intelligence Integration

Let your app's content appear when users point their camera at objects. Uses `IntentValueQuery` with `SemanticContentDescriptor`. Requires iOS 18.

For full Visual Intelligence details, see `apple-intelligence/visual-intelligence/SKILL.md`.

### @UnionValue for Multiple Result Types

When your app can return different entity types from a visual search:

```swift
import AppIntents
import VisualIntelligence

@UnionValue
enum ShopResult {
    case product(ProductEntity)
    case brand(BrandEntity)
    case store(StoreEntity)
}

struct ShopVisualSearchQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [ShopResult] {
        var results: [ShopResult] = []

        let products = await ProductStore.shared.search(labels: input.labels)
        results.append(contentsOf: products.prefix(10).map { .product($0) })

        let brands = await BrandStore.shared.search(labels: input.labels)
        results.append(contentsOf: brands.prefix(5).map { .brand($0) })

        return results
    }
}
```

### OpenIntent per Entity Type

For each entity type in a union, provide an `OpenIntent` so users can tap to open:

```swift
struct OpenProductIntent: AppIntent, OpenIntent {
    static var title: LocalizedStringResource = "Open Product"
    static var openAppWhenRun = true

    @Parameter(title: "Product")
    var target: ProductEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NavigationState.shared.navigate(to: .product(id: target.id))
        }
        return .result()
    }
}

struct OpenBrandIntent: AppIntent, OpenIntent {
    static var title: LocalizedStringResource = "Open Brand"
    static var openAppWhenRun = true

    @Parameter(title: "Brand")
    var target: BrandEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NavigationState.shared.navigate(to: .brand(id: target.id))
        }
        return .result()
    }
}
```

## Onscreen Entities

Associate visible app content with entity identifiers so Siri and ChatGPT can reference what is currently on screen. Available in iOS 26 / macOS 26.

### .userActivity() Modifier

Attach an `EntityIdentifier` to views so the system knows which entity is displayed:

```swift
struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.name).font(.largeTitle)
                Text(recipe.description)
                IngredientsListView(ingredients: recipe.ingredients)
                StepsListView(steps: recipe.steps)
            }
            .padding()
        }
        .userActivity("com.myapp.viewRecipe") { activity in
            activity.title = recipe.name
            activity.targetContentIdentifier = recipe.id
            // Associate with the AppEntity
            activity.appEntity = EntityIdentifier(for: RecipeEntity.self, identifier: recipe.id)
        }
    }
}
```

### EntityIdentifier

Creates a typed reference connecting an on-screen element to an `AppEntity`:

```swift
// Create identifier for a specific entity instance
let identifier = EntityIdentifier(for: RecipeEntity.self, identifier: recipe.id)

// Use in NSUserActivity
activity.appEntity = identifier
```

This enables Siri to say "Tell me about this recipe" while looking at the screen, and the system routes the query to your entity.

### Patterns

```swift
// ✅ Good -- entity identifier matches actual displayed content
.userActivity("com.myapp.viewItem") { activity in
    activity.appEntity = EntityIdentifier(
        for: ItemEntity.self,
        identifier: item.id
    )
}

// ❌ Wrong -- generic activity with no entity association
.userActivity("com.myapp.viewItem") { activity in
    activity.title = item.name
    // No entity identifier -- Siri cannot reference this content
}
```

## Swift Package Support

Share intents across apps or with extensions using `AppIntentsPackage`. Available in iOS 26 / macOS 26.

### AppIntentsPackage Protocol

```swift
// In your Swift package
public struct SharedIntentsPackage: AppIntentsPackage {
    // List other packages this one depends on
    public static var includedPackages: [any AppIntentsPackage.Type] {
        []
    }
}
```

### Including Packages in Your App

```swift
// In your app target
struct MyAppIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [SharedIntentsPackage.self]
    }
}
```

### Use Case

Package support is useful when:
- Multiple apps share the same entity types or intents
- App extensions need access to the same intents as the main app
- You distribute reusable intent functionality as a Swift package

### Patterns

```swift
// ✅ Good -- package declares its dependencies
struct AnalyticsIntentsPackage: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] {
        [CoreDataIntentsPackage.self]
    }
}

// ❌ Wrong -- intents duplicated across targets instead of shared via package
// App target: struct FavoriteIntent: AppIntent { ... }
// Widget target: struct FavoriteIntent: AppIntent { ... }  // Duplicate!
```

## Complete Example: Music Player with Interactive Snippet

```swift
import AppIntents
import SwiftUI

// MARK: - Entity

struct SongEntity: AppEntity {
    var id: String
    var title: String
    var artist: String
    var albumArt: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Song"),
            numericFormat: "\(placeholder: .int) songs"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(artist)",
            image: .init(named: albumArt)
        )
    }

    static var defaultQuery = SongEntityQuery()
}

struct SongEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [SongEntity] {
        await MusicStore.shared.songs(for: identifiers)
    }

    func entities(matching string: String) async throws -> [SongEntity] {
        await MusicStore.shared.search(query: string)
    }

    func suggestedEntities() async throws -> [SongEntity] {
        await MusicStore.shared.recentlyPlayed(limit: 10)
    }
}

// MARK: - Play Intent with Snippet

struct PlaySongIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Song"

    @Parameter(title: "Song")
    var song: SongEntity

    var supportedModes: IntentModes { .background }

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        await MusicPlayer.shared.play(songID: song.id)
        let state = await MusicPlayer.shared.currentState()
        return .result(view: NowPlayingSnippetView(state: state))
    }
}

// MARK: - Snippet Intents

struct PauseSongSnippetIntent: AppIntent, SnippetIntent {
    static var title: LocalizedStringResource = "Pause"

    var supportedModes: IntentModes { .background }

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        await MusicPlayer.shared.pause()
        let state = await MusicPlayer.shared.currentState()
        return .result(view: NowPlayingSnippetView(state: state))
    }
}

struct SkipSongSnippetIntent: AppIntent, SnippetIntent {
    static var title: LocalizedStringResource = "Skip"

    var supportedModes: IntentModes { .background }

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        await MusicPlayer.shared.skipToNext()
        let state = await MusicPlayer.shared.currentState()
        return .result(view: NowPlayingSnippetView(state: state))
    }
}

// MARK: - Snippet View

struct NowPlayingSnippetView: View {
    let state: PlayerState

    var body: some View {
        HStack(spacing: 12) {
            Image(state.albumArt)
                .resizable()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(state.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 12) {
                if state.isPlaying {
                    IntentButton(intent: PauseSongSnippetIntent()) {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                    }
                }

                IntentButton(intent: SkipSongSnippetIntent()) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
            }
        }
        .padding()
    }
}

// MARK: - App Shortcuts

struct MusicShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlaySongIntent(),
            phrases: [
                "Play \(\.$song) in \(.applicationName)",
                "Listen to \(\.$song) on \(.applicationName)"
            ],
            shortTitle: "Play Song",
            systemImageName: "play.fill"
        )
    }
}
```

## References

- [SnippetIntent protocol](https://developer.apple.com/documentation/AppIntents/SnippetIntent)
- [IntentModes](https://developer.apple.com/documentation/AppIntents/IntentModes)
- [AppIntentsPackage](https://developer.apple.com/documentation/AppIntents/AppIntentsPackage)
- [Visual Intelligence integration](https://developer.apple.com/documentation/VisualIntelligence)
- [NSUserActivity](https://developer.apple.com/documentation/foundation/nsuseractivity)
- `/Users/ravishankar/Downloads/docs/AppIntents-Updates.md`
