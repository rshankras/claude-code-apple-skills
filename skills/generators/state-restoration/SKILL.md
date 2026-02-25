---
name: state-restoration
description: Generates state preservation and restoration infrastructure for navigation paths, tab selection, scroll positions, and form data across app launches and background termination. Use when user wants to save/restore app state, remember where the user left off, or persist UI state.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# State Restoration Generator

Generate production state restoration infrastructure that saves and restores app state (selected tab, scroll position, navigation path, form data) across launches and background termination. Uses Codable state models, @SceneStorage, @AppStorage, and custom file-based persistence.

## When This Skill Activates

Use this skill when the user:
- Asks to "add state restoration" or "restore state"
- Wants to "save app state" or "persist UI state"
- Mentions "preserve navigation" or "remember navigation path"
- Asks to "remember scroll position" or "restore scroll position"
- Wants the app to "resume where left off" or "remember where I was"
- Asks about "saving form drafts" or "preserve form data"
- Mentions "tab selection persistence" or "remember selected tab"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for @Observable)
- [ ] Check for existing state saving code
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing state restoration:
```
Glob: **/*StateRestoration*.swift, **/*AppState*.swift, **/*SceneStorage*.swift
Grep: "SceneStorage" or "NavigationPath" or "selectedTab" or "scrollPosition"
```

If existing state management found:
- Ask if user wants to replace or extend it
- If extending, integrate with the existing approach

### 3. Navigation Pattern Detection
Determine which navigation pattern the app uses:
```
Grep: "NavigationStack" or "NavigationSplitView" or "TabView" or "NavigationLink"
```

This affects which restoration components to generate.

## Configuration Questions

Ask user via AskUserQuestion:

1. **What state to restore?** (multi-select)
   - Navigation path (back stack, detail selection)
   - Selected tab (TabView selection)
   - Scroll position (list/scroll view offset)
   - Form data (unsaved drafts and input fields)
   - All of the above — recommended

2. **Storage method?**
   - @SceneStorage / @AppStorage (simple, per-scene, limited to basic types)
   - UserDefaults (shared across scenes, limited size)
   - File-based (Codable to JSON file in Application Support — recommended for complex state)

3. **Restore behavior?**
   - Always restore (seamless resume on every launch)
   - Time-limited (restore only if last session was within N minutes) — recommended
   - Ask user (show "Resume where you left off?" prompt)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `AppState.swift` — Codable struct capturing all restorable state
2. `StateRestorationManager.swift` — @Observable manager with auto-save and restore

### Step 3: Create Feature Files
Based on configuration:
3. `NavigationStateModifier.swift` — If navigation path selected
4. `ScrollRestorationModifier.swift` — If scroll position selected
5. `TabRestorationModifier.swift` — If tab selection selected
6. `FormDraftManager.swift` — If form data selected

### Step 4: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/StateRestoration/`
- If `App/` exists -> `App/StateRestoration/`
- Otherwise -> `StateRestoration/`

## Output Format

After generation, provide:

### Files Created
```
StateRestoration/
├── AppState.swift                  # Codable state model
├── StateRestorationManager.swift   # Auto-save/restore orchestrator
├── NavigationStateModifier.swift   # Navigation path persistence (optional)
├── ScrollRestorationModifier.swift # Scroll position persistence (optional)
├── TabRestorationModifier.swift    # Tab selection persistence (optional)
└── FormDraftManager.swift          # Form draft auto-save (optional)
```

### Integration Steps

**Basic setup in App struct:**
```swift
@main
struct MyApp: App {
    @State private var stateManager = StateRestorationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stateManager)
        }
    }
}
```

**Restore navigation path:**
```swift
struct ContentView: View {
    @Environment(StateRestorationManager.self) private var stateManager

    var body: some View {
        @Bindable var sm = stateManager
        NavigationStack(path: $sm.navigationPath) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route)
                }
        }
        .modifier(NavigationStateModifier(stateManager: stateManager))
    }
}
```

**Restore tab selection:**
```swift
struct MainTabView: View {
    @Environment(StateRestorationManager.self) private var stateManager

    var body: some View {
        @Bindable var sm = stateManager
        TabView(selection: $sm.selectedTab) {
            HomeTab().tag(0)
            SearchTab().tag(1)
            ProfileTab().tag(2)
        }
        .modifier(TabRestorationModifier(stateManager: stateManager))
    }
}
```

**Restore scroll position:**
```swift
struct ItemListView: View {
    let items: [Item]

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(items) { item in
                    ItemRow(item: item)
                }
            }
        }
        .modifier(ScrollRestorationModifier(scrollViewID: "item-list"))
    }
}
```

**Auto-save form drafts:**
```swift
struct ComposeView: View {
    @State private var draftManager = FormDraftManager(formID: "compose")
    @State private var title = ""
    @State private var body = ""

    var body: some View {
        Form {
            TextField("Title", text: $title)
            TextEditor(text: $body)
        }
        .onAppear { draftManager.restore(into: &title, &body, keys: "title", "body") }
        .onChange(of: title) { draftManager.save(key: "title", value: title) }
        .onChange(of: body) { draftManager.save(key: "body", value: body) }
        .onSubmit { draftManager.clearDraft() }
    }
}
```

### Testing

```swift
@Test
func stateRestoredFromDisk() async throws {
    let manager = StateRestorationManager(storage: .file(directory: tempDir))
    manager.selectedTab = 2
    manager.saveState()

    let restored = StateRestorationManager(storage: .file(directory: tempDir))
    restored.restoreState()
    #expect(restored.selectedTab == 2)
}

@Test
func timeLimitedRestoreExpires() async throws {
    let manager = StateRestorationManager(
        storage: .file(directory: tempDir),
        restoreBehavior: .timeLimited(minutes: 30)
    )
    // Simulate state saved 60 minutes ago
    manager.appState.lastSavedDate = Date().addingTimeInterval(-3600)
    manager.saveState()

    let restored = StateRestorationManager(
        storage: .file(directory: tempDir),
        restoreBehavior: .timeLimited(minutes: 30)
    )
    restored.restoreState()
    #expect(restored.selectedTab == 0) // Default, not restored
}

@Test
func formDraftClearedOnSubmit() async throws {
    let draft = FormDraftManager(formID: "test", storage: .file(directory: tempDir))
    draft.save(key: "title", value: "My Draft")
    #expect(draft.value(for: "title") == "My Draft")

    draft.clearDraft()
    #expect(draft.value(for: "title") == nil)
}
```

## Common Patterns

### Save Navigation Path with Codable Routes
```swift
enum Route: Codable, Hashable {
    case detail(id: UUID)
    case settings
    case profile(userID: String)
}

// NavigationPath supports Codable serialization
let representation = navigationPath.codable
let data = try JSONEncoder().encode(representation)
```

### Restore Tab Selection with String Tags
```swift
// Use String tags instead of Int for readability and stability
TabView(selection: $stateManager.selectedTab) {
    HomeView().tag("home")
    SearchView().tag("search")
    ProfileView().tag("profile")
}
```

### Preserve Form Draft with Debounced Save
```swift
// Save draft only after user pauses typing (1 second)
.onChange(of: textContent) {
    draftManager.save(key: "content", value: textContent)
    // Internally debounced — won't write to disk on every keystroke
}
```

## Gotchas

- **@SceneStorage only works with simple types** — String, Int, Double, Bool, URL, Data. For complex state like NavigationPath, use `NavigationPath.CodableRepresentation` converted to Data.
- **NavigationPath Codable limitations** — All types in the path must conform to both Codable and Hashable. If any route type changes between versions, decoding fails silently. Always wrap in try/catch and fall back to empty path.
- **Background termination vs force quit** — State is saved when the app enters background (via `scenePhase`). Force quit from the app switcher does NOT trigger `scenePhase` change on iOS. Save state on every significant change, not just on backgrounding.
- **State migration between versions** — When adding new fields to AppState, provide default values so old JSON files decode without error. Consider a `stateVersion` field for breaking changes.
- **@SceneStorage is per-scene** — On iPad with multiple windows, each scene has its own @SceneStorage. This is usually correct (each window has its own state) but be aware when sharing state across scenes.
- **Avoid saving sensitive data** — Never persist passwords, tokens, or PII in state restoration files. Use Keychain for sensitive data.

## References

- **templates.md** — All production Swift templates
- Related: `generators/persistence-setup` — Core Data / SwiftData persistence layer
- Related: `generators/deep-linking` — URL-based navigation restoration
