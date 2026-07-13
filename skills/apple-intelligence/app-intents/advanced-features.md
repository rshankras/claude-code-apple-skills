# Advanced Features

Intent modes, interactive snippets, visual intelligence integration, onscreen entities, multiple choice, undoable intents, property macros, App Schemas for Siri, interaction donations, and Swift package support. These features require iOS 26 / macOS 26 unless noted otherwise.

## Intent Modes

Control whether your intent runs in the background or needs to come to the foreground. Available in iOS 26 / macOS 26.

### supportedModes Property

```swift
struct SyncDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync Data"

    // Runs entirely in the background -- no UI needed
    static let supportedModes: IntentModes = .background

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

Modes combine — declare every mode the intent supports (WWDC25 275):

```swift
static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
```

### Dynamic Foreground Transition

Start in background, move to foreground only if needed:

```swift
struct EditDocumentIntent: AppIntent {
    static var title: LocalizedStringResource = "Edit Document"

    @Parameter(title: "Document")
    var document: DocumentEntity

    // Start background, but can transition to foreground
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

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

Rules (WWDC25 275):

- `continueInForeground` is only legal under `.foreground(.dynamic)` or `.foreground(.deferred)` modes.
- Check before calling: `systemContext.currentMode.canContinueInForeground` (and `systemContext.currentMode == .foreground` tells you whether you're already there).
- `alwaysConfirm: false` skips the user prompt if the user interacted with the device within the last few seconds.
- It **throws if the launch is denied — always catch this error** and degrade to a background result. (Contrast: `requestConfirmation`/`requestChoice` throw on cancel and must *never* be caught — see Multiple Choice below.)

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

### Pair Background and Foreground Intents

Ship the fast path as a `.background` intent and return the foreground follow-up via `OpensIntent` — the user picks in-and-out vs. jump-into-app (WWDC25 260):

```swift
struct CreateEventIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Event"
    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult & OpensIntent {
        let event = try await EventStore.shared.create(...)
        return .result(opensIntent: OpenEventIntent(target: event))
    }
}
```

❌ Anti-pattern called out in the session: shipping only foreground intents, forcing an app launch for every action (WWDC25 260).

### Patterns

```swift
// ✅ Good -- background intent for data work
static let supportedModes: IntentModes = .background

// ✅ Good -- immediate foreground for camera/AR features
static let supportedModes: IntentModes = .foreground(.immediate)

// ✅ Good -- background plus dynamic foreground for intents that might need UI
static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

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

### Cancellation Throws — Never Catch It

`requestChoice` (and `requestConfirmation`) **throw when the user cancels. Let the error propagate and terminate `perform()`; do not catch it** (WWDC25 275). This is the opposite of `continueInForeground`, whose denial error you always catch and degrade from.

Options can carry a style for destructive actions, and the prompt can include a snippet view (WWDC25 275):

```swift
let archive = Option(title: "Archive", style: .default)
let delete  = Option(title: "Delete",  style: .destructive)
let choice = try await requestChoice(
    between: [.cancel, archive, delete],
    dialog: "Archive or delete \(collection.name)?",
    view: collectionSnippetView(collection)
)
// switch on `choice`
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

## Undoable Intents

`UndoableIntent` gives `perform()` a system-provided `undoManager` (works even in extensions) that keeps intent-driven and UI-driven undo on one stack (WWDC25 275):

```swift
struct DeleteCollectionIntent: UndoableIntent {
    static let title: LocalizedStringResource = "Delete Collection"

    @Parameter(title: "Collection")
    var collection: CollectionEntity

    @Dependency var modelData: ModelData

    func perform() async throws -> some IntentResult {
        await undoManager?.registerUndo(withTarget: modelData) { $0.restore(collection) }
        await undoManager?.setActionName("Delete \(collection.name)")
        try await modelData.delete(collection)
        return .result()
    }
}
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

Prefer `@ComputedProperty` over copying model values into stored entity properties — it defers to the source of truth at read time, so entity values never go stale between resolutions (WWDC25 244):

```swift
// ❌ Copying model values into stored entity properties -- stale snapshots
@Property(title: "Name")
var name: String            // copied at init; the model may have changed since

// ✅ Computed from the source of truth at read time
@ComputedProperty
var name: String { landmark.name }
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

Decision rule (WWDC25 275): **prefer `@ComputedProperty`** (sync derive from the source of truth — lowest overhead, e.g. a `UserDefaults` read); use `@DeferredProperty` only when computation is genuinely expensive (e.g. fetched from a server). A deferred getter is `async throws` and is invoked only when a system feature actually asks:

```swift
@DeferredProperty
var crowdStatus: Int {
    get async throws { await modelData.getCrowdStatus(self) }
}
```

### UniqueAppEntity

For singleton entities — exactly one instance ever exists, e.g. a Settings entity — conform to `UniqueAppEntity`: no meaningful id/query boilerplate needed, and it pairs naturally with `@ComputedProperty` reads (WWDC25 275).

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

A snippet is itself an intent whose `perform()` returns the view (WWDC25 275). Two result-type protocols pair up: the **main** intent returns `ShowsSnippetIntent`; the **snippet** intent returns `ShowsSnippetView`. Buttons inside the snippet view run ordinary `AppIntent`s that mutate state; the system then re-creates and re-runs the SnippetIntent to re-render.

```swift
// The main intent hands off to a snippet intent
struct ShowTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Timer"

    func perform() async throws -> some IntentResult & ShowsSnippetIntent {
        return .result(snippetIntent: TimerSnippetIntent())
    }
}

// The snippet intent is a stateless render function --
// it fetches fresh state and returns the view, nothing else
struct TimerSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Timer Snippet"

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let timer = await TimerService.shared.activeTimer()   // fetched on every render
        return .result(view: TimerSnippetView(timer: timer))
    }
}

// Button intents are plain AppIntents that mutate state
struct PauseTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Timer"
    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult {
        await TimerService.shared.pauseActive()
        return .result()
    }
}

struct ResumeTimerIntent: AppIntent {
    static let title: LocalizedStringResource = "Resume Timer"
    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult {
        await TimerService.shared.resumeActive()
        return .result()
    }
}

// The snippet view triggers button intents with Button(intent:)
struct TimerSnippetView: View {
    let timer: TimerState

    var body: some View {
        VStack(spacing: 12) {
            Text(timer.remaining, format: .time(pattern: .minuteSecond))
                .font(.system(size: 36, weight: .medium, design: .monospaced))

            HStack(spacing: 16) {
                if timer.isRunning {
                    Button(intent: PauseTimerIntent()) {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(intent: ResumeTimerIntent()) {
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

### SnippetIntent Is a Stateless Render Function

The update cycle: any `Button(intent:)`/`Toggle(intent:)` inside the snippet view runs its intent to completion, then the system **re-creates and re-runs the SnippetIntent** to re-render. Entity parameters are re-fetched fresh from their queries on every cycle — no manual wiring (WWDC25 275).

Anti-patterns Apple states explicitly (WWDC25 275):

- **Never mutate app state inside a SnippetIntent's `perform()`** — it runs many times, including extra runs the system triggers for environment changes (a dark-mode switch). Mutation belongs in the button intents.
- **Don't stash changing values in snippet parameters.** Only AppEntities (re-fetched each cycle) and truly immutable primitives are safe parameters; everything else must be fetched inside `perform()`.
- **Don't render slowly** — the snippet re-runs synchronously with interactions; a slow `perform()` is a visibly unresponsive snippet.

More snippet mechanics (WWDC25 275):

- Mid-task refresh from app code: call the static `reload()` on the snippet type (e.g. `TimerSnippetIntent.reload()`) to force a re-render when new state arrives outside an interaction.
- The system keeps the app process alive while a snippet is visible — you may retain state in memory across a confirmation → result sequence.
- Animations: drive with standard SwiftUI `contentTransition` — state diffs across re-renders animate.
- `@Dependency` works inside snippet intents; register dependencies as early as possible in the app lifecycle (`AppDependencyManager.shared.add { ... }` in the App `init()`) — intents can run before UI exists, and a late-registered dependency crashes resolution (WWDC25 244).

### Confirmation Snippets

Present an interactive snippet as the confirmation UI (WWDC25 275):

```swift
try await requestConfirmation(
    actionName: .order,
    snippetIntent: OrderPreviewSnippetIntent(order: order)
)
// Cancel throws -- let it propagate and terminate perform(); never catch it
```

### Patterns

```swift
// ✅ Good -- mutation in a button intent; the SnippetIntent only renders
struct ToggleLikeIntent: AppIntent { /* mutates the store */ }
struct PostSnippetIntent: SnippetIntent { /* fetches state, returns view */ }

// ❌ Wrong -- mutating state inside a SnippetIntent's perform()
struct LikeSnippetIntent: SnippetIntent {
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        await store.toggleLike()   // runs on EVERY re-render, incl. dark-mode switches
        return .result(view: PostView())
    }
}

// ✅ Good -- Button(intent:) in the snippet view
Button(intent: ToggleLikeIntent()) {
    Label("Like", systemImage: "heart")
}

// ❌ Wrong -- closure-based Button in a snippet view (cannot run in your app)
Button("Like") {
    // This closure has nowhere to run -- snippets are rendered out of process
}
```

## Visual Intelligence Integration

Let your app's content appear when users point their camera at objects. Uses `IntentValueQuery` with `SemanticContentDescriptor`. Requires iOS 26 (WWDC25 275).

For full Visual Intelligence details, see `apple-intelligence/visual-intelligence/SKILL.md`.

Two hard rules:

- An app can have only **one** `IntentValueQuery` that accepts a `SemanticContentDescriptor` (WWDC26 297) — multiple result types must flow through a single `@UnionValue` enum, as below.
- Results render from each entity's `DisplayRepresentation`, and tapping a result runs your `OpenIntent` whose `target` type matches the entity. **No OpenIntent for the entity type = your app can't appear in image-search results** (WWDC25 275).

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

## Structured Search and Index Maintenance (WWDC26 343)

For content you don't index ahead of time (large, server-side, or fast-changing), `IntentValueQuery` also powers Siri's **structured search**. Unlike an `EntityQuery`, the input is a structured search value from the system, and you may return more than one entity type via `@UnionValue`:

```swift
struct AudioIntentValueQuery: IntentValueQuery {
    func values(for input: AudioSearch) async throws -> [AudioEntity] {
        // AudioEntity is a @UnionValue of song | playlist
        switch input.criteria {
        case .searchQuery(let query):
            return try await searchResults(for: query)     // relevant utterance fragment
        case .unspecified:
            return try await likedSongResults()            // vague request -> sensible default
        case .url(let url):
            return try await entities(from: url)           // "that playlist Glow sent me"
        }
    }
}
```

System input types like `AudioSearch` and `IntentPerson` are supported; the full criteria set is in the docs (WWDC26 343).

Related pieces (WWDC26 343):

- **`IndexedEntityQuery`**: adopt it so Spotlight can ask your app to *reindex* its entities. Not needed if you already support reindexing via Core Spotlight-level APIs.
- **Semantic index maintenance**: index new entities on creation; update entries when key properties change (especially properties used in the display representation); delete entries when content is removed.
- **In-app search** (`.system.searchInApp` schema): Siri hands you the search string and `perform()` re-runs the search in your own UI. Works regardless of which other domains you adopt, even without indexing. (This schema is the renamed form of the iOS 17 `.system.search` schema.)

Apple's adoption priority order (WWDC26 343): entity `DisplayRepresentation`s → semantic index (kept fresh) → `IntentValueQuery` + in-app search → view/system annotations → interaction donations.

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
            activity.appEntityIdentifier = EntityIdentifier(for: RecipeEntity.self, identifier: recipe.id)
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
activity.appEntityIdentifier = identifier
```

This enables Siri to say "Tell me about this recipe" while looking at the screen, and the system routes the query to your entity. Setting `appEntityIdentifier` on the visible view's `NSUserActivity` is also what prioritizes that entity in Spotlight suggestions while it's on screen (WWDC25 275).

For ChatGPT to consume the entity's *content* (not just reference it), conform the entity to `Transferable` exporting types it understands: `.pdf`, plain text, rich text (WWDC25 275).

### Choosing an Annotation API

Without annotations, Siri's screen understanding is limited to exactly what's in the pixels. Four options — pick by what's on screen (WWDC26 343):

1. **NSUserActivity** — the screen is dedicated to one primary item (a detail view, a compose screen): set `activity.appEntityIdentifier` as above.
2. **View entity annotation** — the entity is one item among several: `.appEntityIdentifier(EntityIdentifier(...))` on the item's view.
3. **Collection annotation** — lists/collections with many entities: annotate the `List` itself with `forSelectionType:`. Identifiers are fetched lazily, and entities that were selected then scrolled off screen stay visible to Siri.
4. **Custom canvas annotation** — non-standard drawn views (a piano-roll canvas).

```swift
// ❌ Per-row .appEntityIdentifier on long lists -- annotations vanish
//    as soon as the row leaves the view hierarchy (WWDC26 343)
ForEach(tracks) { track in
    TrackRow(track: track)
        .appEntityIdentifier(EntityIdentifier(for: SongEntity.self, identifier: track.id))
}

// ✅ Collection annotation -- lazy fetch + survives scroll-off
List(tracks) { track in
    TrackRow(track: track)
}
.appEntityIdentifier(forSelectionType: Track.ID.self) { trackID in
    EntityIdentifier(for: SongEntity.self, identifier: trackID)
}
```

UIKit/AppKit support all of these: `AppEntityAnnotatable`, `UICollectionViewAppIntentsDataSource`, `appEntityUIElementProvider` — the latter also powers contextual menu items (WWDC26 343).

### Fast Display Representations for On-Screen Resolution

If Siri can't understand on-screen entities quickly enough, it asks to clarify or acts on the wrong thing — and people abandon the request. Implement component-based display representation queries so Siri can fetch just the text representation and skip loading full content (WWDC26 343):

```swift
extension PlaylistQuery {
    func displayRepresentations(
        for identifiers: [PlaylistEntity.ID],
        requestedComponents: DisplayRepresentation.Components = .text
    ) async throws -> [PlaylistEntity.ID: DisplayRepresentation] {
        // return lightweight text-only representations
    }
}
```

### Entity Annotations on Notifications, Now Playing, and AlarmKit

The same entity-annotation pattern extends to three system integrations so people can act on your content wherever they meet it (WWDC26 343):

- **UserNotifications**: `content.appEntityIdentifiers = [EntityIdentifier(for: MessageEntity.self, identifier: message.id)]` on `UNMutableNotificationContent` — enables announced-notification actions on AirPods ("Reply, ...").
- **Now Playing**: set `appEntityIdentifiers` on `MusicContent` in your `MediaSessionRepresentable` conformance, ordered **most specific → least specific** (song, artist, playlist) — enables "Play the live version."
- **AlarmKit**: pass a single `EntityIdentifier` to the `appEntityIdentifier:` parameter of `AlarmManager.AlarmConfiguration.alarm(...)` — act on firing alarms/timers ("Snooze it").

❌ Hard limit: `TransientAppEntity` cannot be used with any of these three APIs — transient entities have no persistent identifiers (WWDC26 343).

### Patterns

```swift
// ✅ Good -- entity identifier matches actual displayed content
.userActivity("com.myapp.viewItem") { activity in
    activity.appEntityIdentifier = EntityIdentifier(
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

## App Schemas: Siri-Executable Intents

A schema is a fixed "shape" — a declared set of inputs and outputs — that Apple's foundation models are trained against. If your App Intent matches the shape, you inherit Apple's model training and never touch natural-language handling: "all you need to do is write a perform method" (WWDC24 10133). A plain AppIntent surfaces in Shortcuts/Spotlight/widgets; a schema-conforming intent is additionally *executable by Siri* from natural language (WWDC26 240).

Request lifecycle (WWDC24 10133): user request → Apple Intelligence models predict a schema → routed to a toolbox of all schema-conforming App Intents on device, grouped by schema → your `perform()` is invoked.

### Assistant Schema Macros (iOS 18)

12 App Intent domains ship in iOS 18 (Mail and Photos first, the rest rolling out after), with schemas for over 100 kinds of intents (WWDC24 10133):

```swift
// Schema-conforming intent -- no title/metadata needed; shape is known at compile time
@AssistantIntent(schema: .photos.createAlbum)
struct CreateAlbumIntent: AppIntent {
    @Parameter var name: String
    func perform() async throws -> some ReturnsValue<AlbumEntity> { ... }
}

// Entities and enums referenced by an assistant intent MUST also be schema-exposed
@AssistantEntity(schema: .photos.asset)
struct AssetEntity: IndexedEntity { ... }

@AssistantEnum(schema: .photos.assetType)
enum AssetType: String, AppEnum { ... }
```

- Shapes are **compile-enforced** (WWDC24 10133): an unexposed referenced entity/enum, or a missing required entity property, is a build error. Xcode offers code snippets that pre-fill a schema's required shape.
- Shapes are extensible: an `@AssistantIntent` may add optional parameters, an `@AssistantEntity` optional properties; `@AssistantEnum` imposes no shape on cases at all (WWDC24 10133).
- Test via the Shortcuts app — schema-conforming intents automatically appear there; the same intents light up in Siri as domains roll out, with no separate Siri test harness (WWDC24 10133).

### The Unified Macro Form (WWDC26)

The schema moves onto the ordinary macros — `@AppEntity(schema:)` / `@AppIntent(schema:)` replace the separate `@Assistant*` macros (WWDC26 240, WWDC25 275). Same domain concept, new adoption surface and tooling:

```swift
@AppEntity(schema: .messages.message)
struct MessageEntity: IndexedEntity { ... }

@AppIntent(schema: .audio.addToPlaylist)
struct AddToPlaylistIntent { ... }

// The system open schema -- called when someone taps an entity result in Spotlight/Siri
@AppIntent(for: .system.open, isDefault: true)
struct OpenEventIntent: AppIntent {
    var target: EventEntity
    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationManager.shared.navigate(to: target)
        return .result()
    }
}
```

Rules and mechanics:

- Domains named across the WWDC26 sessions: **messages** (sendMessage, draftMessage), **calendar** (event/calendar/attendee + create/update/delete + status enums), **audio** (song, addToPlaylist, playAudio), **clock** (createTimer; stopwatch), **maps** (NavigationSession), **system** (`.system.open`, `.system.searchInApp`), **visualIntelligence** (semanticContentSearch), plus mail, photos, contacts, documents (WWDC26 240).
- **Multi-schema completeness is compile-enforced**: adopting `sendMessage` without `draftMessage` is a build error, not a runtime failure — and the fix-it generates a full sample adoption of the missing schema (WWDC26 240).
- Xcode schema snippets: typing a domain prefix (e.g. `calendar_`) autocompletes code snippets that scaffold the entity/intent with the schema's required shape (WWDC26 344).
- Optional schema properties your app doesn't use simply stay unset; app-specific non-schema properties may be added to the entity (WWDC26 344).
- Intents that mutate UI state must run on the main actor (WWDC26 240).
- Perform pattern: "resolve the intent's parameters into something the data layer understands, perform the action, and return the result as an entity" — Siri does the interpreting, clarifying, and confirming, including automatic confirmation before destructive actions and disambiguation when multiple entities match (WWDC26 344).
- Entity resolution order (WWDC26 240): model content as app entities → conform each to a schema → adopt `IndexedEntity` where data is indexable (semantic matching, fewer follow-up questions); fall back to `EntityStringQuery` where it isn't (large/server-side/fast-changing data — no semantic understanding, full control).
- Values reached only through a parent entity (an attendee of an event) should be `TransientAppEntity` — no query, no index; indexing each attendance would create duplicative Spotlight results (WWDC26 344).

### Update Intents: valueState, Not nil-Checks

In an update intent, `nil` is ambiguous — "don't change" vs "remove". The `@AppIntent` macro wraps each property in an `IntentParameter` exposing `valueState` (WWDC26 344):

```swift
// ❌ nil-check -- can't tell "clear the value" from "leave unchanged"
if let recurrence { updatedEvent.recurrenceRule = recurrence }

// ✅ Inspect valueState via the projected parameter
if case .set(let recurrence) = $recurrence {
    updatedEvent.recurrenceRule = recurrence   // .set(nil) here means "clear it"
}
// .unset -> parameter wasn't part of the request; leave unchanged
```

`.set(value)` = new value provided; `.set(nil)` = explicitly cleared ("do not repeat this event"); `.unset` = not mentioned. Applies to any optional parameter where clearing is meaningful.

### Testing Ladder

Validate in this order (WWDC26 240):

1. **AppIntentsTesting framework** — invoke intents entirely in isolation (no Siri), pass parameters, validate results like any integration test. Fastest and most reliable way to validate business logic.
2. **Shortcuts app** — validate the *shape* of the intent: parameters, configuration, presentation.
3. **Spotlight** — validate content integration: entities indexed, discoverable, linkable — confirm Siri can find the right data before it ever tries to act on it.
4. **Siri end-to-end** — natural language + entity resolution + on-screen context + cross-app flows together.

## Custom Siri Responses (WWDC26 343)

By default, return an empty `IntentResult` and Siri crafts the response itself. To customize:

- Add `ProvidesDialog` and return `IntentDialog(full:supporting:)`. **The `full` string is read on voice-only devices (AirPods) and must describe what happened on its own; `supporting` is the short string shown alongside UI:**

```swift
func perform() async throws -> some IntentResult & ProvidesDialog {
    .result(dialog: IntentDialog(
        full: "Added \(song.title) to the \(playlist.title) mix tape.",
        supporting: "Added"))
}
```

- Mid-perform clarifying question via the projected parameter:

```swift
try await $label.requestValue("You already have a timer running. What should we call this one?")
```

  Ask clarifying questions sparingly to avoid friction (WWDC26 343).
- Add `ShowsSnippetView` and return `.result(dialog:view:)` for a custom visual response; keep snippet views simple and lightweight (WWDC26 343, 344).
- Customize the entity's `DisplayRepresentation(title:subtitle:image:)` first — it's the entity's system-wide visual identity across Siri responses, disambiguation lists, question answering, Spotlight, and Shortcuts (WWDC26 343).
- Verify responses sound natural on all platforms including voice-only; customize only where it adds value (WWDC26 343).

## Interaction Donations (WWDC26 343)

Apple Intelligence learns from Siri/Shortcuts usage but **cannot see actions taken in your app's UI** — donations fill that gap. Each donation is a hint that a person took a specific action, stored as schema-conforming App Intents in a temporary transcript; over time Siri infers preferences (e.g. which messaging app to use for a contact):

```swift
try await IntentDonationManager.shared.donate(intent: intent, result: .result(value: result))
```

Rules (WWDC26 343):

- Donate **only UI-originated interactions** — add a flag to shared helpers so intent-originated calls don't double-donate.
- Populate the intent's parameters AND its result before donating.
- ❌ Over-donating: "If your app donates excessively, the system may ignore those donations." Donations must reflect real user behavior.
- Donations also keep Siri aware of **ongoing activities**: intents that start/stop NavigationSessions (Maps domain) or start/stop/pause/lap stopwatches (Clock domain) let "add a stop" or "pause it" work mid-activity.

## Entity Ownership and Confirmations (WWDC26 343)

Siri auto-confirms intents with meaningful side effects, and confirms *more* for content shared with others (updating a group event vs a personal one). Default assumption: entities are private to the person, so confirmations may be skipped. Inform that decision with `OwnershipProvidingEntity`:

```swift
@AppEntity(schema: .calendar.event)
struct EventEntity: OwnershipProvidingEntity {
    var ownership: EntityOwnership {   // .shared, .public, or .unknown
        attendees.isEmpty ? .unknown : .shared
    }
}
```

Rules (WWDC26 343): conform **only** entities people can actually share or make public; keep the ownership state up to date every time the system requests the entity. Entity DisplayRepresentations are reused as the confirmation visuals.

## Swift Package Support

Share intents across apps or with extensions using `AppIntentsPackage`. Available in iOS 26 / macOS 26 — this extends App Intents types to Swift packages and static libraries; before that, only frameworks and dynamic libraries could host them (WWDC25 244).

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

### Every Consuming Target Must Register the Package

Every target that shares intent types must declare an `AppIntentsPackage`, and **every consuming target — the app AND each extension — must list the shared package in `includedPackages`**. Forgetting it in ANY consuming target means those types are missing from that target's metadata at runtime (WWDC25 244):

```swift
public struct TravelTrackingKitPackage: AppIntentsPackage {}      // shared library

struct TravelTrackingPackage: AppIntentsPackage {                 // app target
    static var includedPackages: [any AppIntentsPackage.Type] {
        [TravelTrackingKitPackage.self]
    }
}
// Repeat the registration in the widget target, the extension target, ...
```

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

// ❌ Wrong -- widget target consumes shared intent types but never lists the
// package in its own AppIntentsPackage -- types silently missing at runtime
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

// MARK: - Play Intent hands off to the snippet intent

struct PlaySongIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Song"

    @Parameter(title: "Song")
    var song: SongEntity

    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult & ShowsSnippetIntent {
        await MusicPlayer.shared.play(songID: song.id)
        return .result(snippetIntent: NowPlayingSnippetIntent())
    }
}

// MARK: - Snippet Intent (stateless render function -- WWDC25 275)

struct NowPlayingSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Now Playing"

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let state = await MusicPlayer.shared.currentState()   // fetched fresh every render
        return .result(view: NowPlayingSnippetView(state: state))
    }
}

// MARK: - Button Intents (mutations live here, never in the snippet intent)

struct PauseSongIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause"

    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult {
        await MusicPlayer.shared.pause()
        return .result()
    }
}

struct SkipSongIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip"

    static let supportedModes: IntentModes = .background

    func perform() async throws -> some IntentResult {
        await MusicPlayer.shared.skipToNext()
        return .result()
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
                    Button(intent: PauseSongIntent()) {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                    }
                }

                Button(intent: SkipSongIntent()) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
            }
        }
        .padding()
    }
}

// After PauseSongIntent/SkipSongIntent complete, the system re-runs
// NowPlayingSnippetIntent to re-render the snippet with fresh state.

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
- Local captured doc (optional): `~/Downloads/docs/AppIntents-Updates.md` — read if present; skip silently if absent.
