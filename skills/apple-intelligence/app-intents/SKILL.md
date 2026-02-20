---
name: app-intents
description: App Intents for Siri, Shortcuts, Spotlight, and Apple Intelligence integration including intent modes, interactive snippets, visual intelligence, and entity indexing. Use when implementing Siri integration, App Shortcuts, or Spotlight indexing.
allowed-tools: [Read, Glob, Grep]
---

# App Intents

Build intents that expose your app's functionality to Siri, Shortcuts, Spotlight, and Apple Intelligence. Covers the full App Intents framework from basic actions through advanced features like interactive snippets, intent modes, visual intelligence integration, and Spotlight entity indexing.

## When This Skill Activates

- User wants to add Siri or Shortcuts integration
- User asks about App Intents, AppIntent, or AppEntity
- User needs Spotlight indexing for app content
- User wants to create App Shortcuts with voice phrases
- User is implementing interactive snippets for Siri results
- User asks about intent modes (foreground, background)
- User needs visual intelligence integration via App Intents
- User wants onscreen entity support for Siri/ChatGPT
- User asks about Swift package support for App Intents

## Decision Tree

```
What do you need?
|
+-- Expose an action to Siri/Shortcuts
|   +-- Simple action, no UI needed
|   |   --> Basic AppIntent (intents-basics.md)
|   +-- Needs to show UI or ask user questions
|   |   --> Intent Modes + Interactive Snippets (advanced-features.md)
|   +-- Needs a predictable voice phrase
|       --> App Shortcuts (intents-basics.md)
|
+-- Make content searchable
|   +-- In Spotlight
|   |   --> IndexedEntity + @Property (entities-spotlight.md)
|   +-- In Visual Intelligence
|   |   --> IntentValueQuery + SemanticContentDescriptor (advanced-features.md)
|   +-- As onscreen entities for Siri/ChatGPT
|       --> .userActivity() + EntityIdentifier (advanced-features.md)
|
+-- Show rich results in Siri
|   +-- Static display only
|   |   --> .result(view:) snippet (advanced-features.md)
|   +-- Interactive buttons/controls
|       --> SnippetIntent protocol (advanced-features.md)
|
+-- Present choices to the user
|   --> requestChoice(between:) (advanced-features.md)
|
+-- Share intents via Swift Package
    --> AppIntentsPackage protocol (advanced-features.md)
```

## API Availability

| Feature | Minimum OS | Framework |
|---------|-----------|-----------|
| `AppIntent` protocol | iOS 16 / macOS 13 | AppIntents |
| `AppEntity` protocol | iOS 16 / macOS 13 | AppIntents |
| `AppShortcutsProvider` | iOS 16 / macOS 13 | AppIntents |
| `@Parameter` macro | iOS 16 / macOS 13 | AppIntents |
| `IndexedEntity` protocol | iOS 18 / macOS 15 | AppIntents |
| `@Property` with `indexingKey` | iOS 18 / macOS 15 | AppIntents |
| Intent Modes (`supportedModes`) | iOS 26 / macOS 26 | AppIntents |
| `requestChoice(between:)` | iOS 26 / macOS 26 | AppIntents |
| `@ComputedProperty` | iOS 26 / macOS 26 | AppIntents |
| `@DeferredProperty` | iOS 26 / macOS 26 | AppIntents |
| `SnippetIntent` protocol | iOS 26 / macOS 26 | AppIntents |
| `AppIntentsPackage` protocol | iOS 26 / macOS 26 | AppIntents |
| Onscreen entities (`.userActivity()`) | iOS 26 / macOS 26 | AppIntents |
| `@UnionValue` | iOS 18 / macOS 15 | AppIntents |

## Quick Reference

| Task | Type/API | Reference File |
|------|----------|----------------|
| Define an action | `AppIntent` protocol | `intents-basics.md` |
| Accept parameters | `@Parameter` macro | `intents-basics.md` |
| Create voice phrases | `AppShortcutsProvider` | `intents-basics.md` |
| Define a data entity | `AppEntity` protocol | `entities-spotlight.md` |
| Index in Spotlight | `IndexedEntity` protocol | `entities-spotlight.md` |
| Mark indexable fields | `@Property(indexingKey:)` | `entities-spotlight.md` |
| Run in background/foreground | `supportedModes` | `advanced-features.md` |
| Continue in foreground | `continueInForeground()` | `advanced-features.md` |
| Show result UI | `.result(view:)` | `advanced-features.md` |
| Interactive result UI | `SnippetIntent` protocol | `advanced-features.md` |
| Present choices | `requestChoice(between:)` | `advanced-features.md` |
| Visual intelligence search | `IntentValueQuery` | `advanced-features.md` |
| Onscreen entity association | `.userActivity()` modifier | `advanced-features.md` |
| Computed/deferred properties | `@ComputedProperty`, `@DeferredProperty` | `advanced-features.md` |
| Share via packages | `AppIntentsPackage` | `advanced-features.md` |

## Process

### 1. Identify Integration Needs

Read the user's code or requirements to determine:
- What actions should be exposed to Siri/Shortcuts
- What content should be searchable in Spotlight
- Whether interactive snippets are needed for Siri results
- Whether the intent needs foreground UI or can run in background
- Target platform and minimum OS version

### 2. Load Relevant Reference Files

Based on the need, read from this directory:
- **intents-basics.md** -- AppIntent protocol, @Parameter, perform(), App Shortcuts
- **entities-spotlight.md** -- AppEntity, IndexedEntity, Spotlight indexing, @Property
- **advanced-features.md** -- Intent modes, interactive snippets, visual intelligence, onscreen entities, choices, packages

### 3. Review or Implement

Apply patterns from the reference files. Check for common mistakes (see Top Mistakes below).

### 4. Cross-Reference

- For **Visual Intelligence camera search**, see `apple-intelligence/visual-intelligence/`
- For **Foundation Models on-device LLM**, see `apple-intelligence/foundation-models/`
- For **deep linking from intents**, see `generators/deep-linking/` skill

## Top Mistakes

These are the most frequent errors when implementing App Intents.

### 1. Missing static metadata

```swift
// ❌ Wrong -- no title or description
struct MyIntent: AppIntent {
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// ✅ Correct -- static title is required
struct MyIntent: AppIntent {
    static var title: LocalizedStringResource = "Do Something"
    static var description: IntentDescription = "Performs the action"

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
```

### 2. Forgetting to index entities after changes

```swift
// ❌ Wrong -- entities updated but Spotlight not notified
func saveRecipe(_ recipe: Recipe) {
    database.save(recipe)
}

// ✅ Correct -- reindex after mutations
func saveRecipe(_ recipe: Recipe) async throws {
    database.save(recipe)
    try await CSSearchableIndex.default().indexAppEntities()
}
```

### 3. Using foreground intent for background-safe work

```swift
// ❌ Wrong -- forces app to foreground for a simple toggle
struct ToggleFavoriteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"
    static var openAppWhenRun = true  // Unnecessary

    func perform() async throws -> some IntentResult {
        toggleFavorite()
        return .result()
    }
}

// ✅ Correct -- runs silently in background
struct ToggleFavoriteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"

    var supportedModes: IntentModes { .background }

    func perform() async throws -> some IntentResult {
        toggleFavorite()
        return .result()
    }
}
```

### 4. Not providing EntityStringQuery for entities

```swift
// ❌ Wrong -- entity has no way to be queried
struct NoteEntity: AppEntity {
    var id: String
    var title: String
    // Missing: static var defaultQuery
}

// ✅ Correct -- provides a query so Siri can resolve entities
struct NoteEntity: AppEntity {
    var id: String
    var title: String

    static var defaultQuery = NoteEntityQuery()
    // ... typeDisplayRepresentation, displayRepresentation
}
```

### 5. Returning too many Spotlight results

```swift
// ❌ Wrong -- indexing thousands of items at once blocks the main thread
func indexAll() async throws {
    let allItems = database.fetchAll()  // 50,000 items
    try await CSSearchableIndex.default().indexAppEntities()
}

// ✅ Correct -- batch index and run off main thread
func indexAll() async throws {
    try await CSSearchableIndex.default().indexAppEntities(
        of: RecipeEntity.self
    )
}
```

## Review Checklist

Before shipping App Intents integration:

- [ ] Every `AppIntent` has a `static var title` and `static var description`
- [ ] Every `AppEntity` has `typeDisplayRepresentation`, `displayRepresentation`, and `defaultQuery`
- [ ] `@Parameter` properties have descriptive titles
- [ ] Entities used in Shortcuts have `EntityStringQuery` or `EntityPropertyQuery`
- [ ] `IndexedEntity` types call `CSSearchableIndex.default().indexAppEntities()` after data changes
- [ ] `@Property` fields used in indexing have `indexingKey` set
- [ ] App Shortcuts have clear, natural-language phrases with `\(.applicationName)`
- [ ] Intent modes match the actual work: background for data ops, foreground for UI
- [ ] Interactive snippets use `SnippetIntent` (not plain `AppIntent`)
- [ ] `perform()` handles errors gracefully and returns meaningful dialog
- [ ] Intents are tested in Shortcuts app and via Siri voice
- [ ] Deep links from entity results navigate to the correct screen

## References

- [App Intents framework](https://developer.apple.com/documentation/AppIntents)
- [Making your app's functionality available to Siri](https://developer.apple.com/documentation/AppIntents/making-your-apps-functionality-available-to-siri)
- [App Shortcuts](https://developer.apple.com/documentation/AppIntents/app-shortcuts)
- [IndexedEntity](https://developer.apple.com/documentation/AppIntents/IndexedEntity)
- [Spotlight integration](https://developer.apple.com/documentation/CoreSpotlight)
- `/Users/ravishankar/Downloads/docs/AppIntents-Updates.md`
