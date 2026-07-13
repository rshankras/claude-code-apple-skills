# App Intents Basics

Core patterns for the AppIntent protocol, parameters, the `perform()` method, and App Shortcuts with voice phrases.

## What Deserves to Be an Intent

Scope doctrine from Apple's design sessions:

- **"Anything your app does should be an App Intent"** (WWDC24 10176). First-time adopters can start with the most habitual features, but the end-state is full coverage of your app's tasks. Counterweight: flexibility must not come at the cost of comprehensibility — a rich set of flexible intents beats a pile of unclear, brittle ones.
- Vocabulary: **intents are verbs, entities are nouns, enums are fixed nouns**, and App Shortcuts are sentences that promote one intent (WWDC25 244, WWDC24 10210). If a set of values is fixed at compile time, model it as an `AppEnum`; if instances are user data or unbounded, use an `AppEntity` + query — don't model dynamic data as an enum (WWDC25 244).
- Start from the fundamental verb families seen across Shortcuts — Open, Create, Show, Set — when deciding what to surface first (WWDC24 10176).
- Name intents for **user-meaningful tasks, never implementation names or UI gestures** (WWDC24 10210).

```swift
// ❌ One intent per variant of the same task (WWDC24 10176)
struct OpenWorkReminders: AppIntent { }
struct OpenHomeReminders: AppIntent { }
struct OpenGroceryReminders: AppIntent { }

// ✅ One flexible intent, variant as a parameter
struct OpenRemindersList: AppIntent {
    @Parameter(title: "List") var list: ReminderListEntity
}

// ❌ Intent that triggers a specific UI element -- hides the actual task
struct TapCancelButtonIntent: AppIntent { }

// ✅ Model the underlying task those elements perform
struct SaveDraftIntent: AppIntent { }
struct DeleteDraftIntent: AppIntent { }
```

- Apps with **Live Activities, audio playback, or recording** should provide intents that run those from the background — ideal for simple intents needing no further in-app action (WWDC24 10176).

## The AppIntent Protocol

Every intent conforms to `AppIntent` and must provide a static title and a `perform()` method.

### Minimal Intent

```swift
import AppIntents

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Settings"
    static var description: IntentDescription = "Opens the app settings screen"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NavigationState.shared.navigate(to: .settings)
        }
        return .result()
    }
}
```

### Metadata Is Extracted at Build Time

Everything in the App Intents surface is read at **build time, per target**, by a static metadata extraction pass (WWDC25 244). `title`, `typeDisplayRepresentation`, and `caseDisplayRepresentations` must be **constant literals** — computed properties or function calls silently break extraction.

```swift
// ❌ Computed title -- extraction silently fails
static var title: LocalizedStringResource { makeTitle() }

// ✅ Constant literal (static let)
static let title: LocalizedStringResource = "Open Settings"
```

### Intent with Dialog Result

Return a spoken/displayed response to the user:

```swift
struct CheckBalanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Balance"

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let balance = await AccountService.shared.currentBalance()
        return .result(
            value: balance.formatted,
            dialog: "Your balance is \(balance.formatted)."
        )
    }
}
```

### Intent that Opens the App

```swift
struct ComposeMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Compose Message"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppState.shared.startNewMessage()
        }
        return .result()
    }
}
```

Opening the app is common, expected behavior — specifically to *show the user the change the intent made* (WWDC24 10176). Exactly two open patterns:

1. The intent **inherently opens to a view** (Open Stopwatch) → conform to `OpenIntent` (see "OpenIntent for Entities" below); it implies `openAppWhenRun`.
2. The intent **completes with a UI change or shows search results** (Create Board finishing on the new board) → the system surfaces this as an **"Open When Run" toggle, default on**, so people can switch it off inside multi-step shortcuts where several intents run back-to-back without each app foregrounding.

When opening to show a result, land **directly on the changed content with no additional in-app animations** — the user should be able to start working immediately (WWDC24 10176).

## Parameters

Use `@Parameter` to accept input from Siri or Shortcuts.

### Basic Parameter Types

```swift
struct CreateReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Reminder"

    @Parameter(title: "Title")
    var reminderTitle: String

    @Parameter(title: "Due Date")
    var dueDate: Date?

    @Parameter(title: "Priority", default: .medium)
    var priority: ReminderPriority

    @Parameter(title: "Notes")
    var notes: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let reminder = Reminder(
            title: reminderTitle,
            dueDate: dueDate,
            priority: priority,
            notes: notes
        )
        try await ReminderStore.shared.save(reminder)
        return .result(dialog: "Created reminder: \(reminderTitle)")
    }
}
```

### Entity Parameters

Reference an `AppEntity` as a parameter so Siri can resolve it:

```swift
struct OpenNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Note"
    static var openAppWhenRun = true

    @Parameter(title: "Note")
    var note: NoteEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NavigationState.shared.navigate(to: .note(id: note.id))
        }
        return .result()
    }
}
```

A parameter that refers to an entity must BE the entity, not data describing it (WWDC24 10210):

```swift
// ❌ Data describing the entity
@Parameter(title: "Note") var noteName: String     // or a UUID

// ✅ The entity itself -- system gets picker, search, validation for free
@Parameter(title: "Note") var note: NoteEntity
```

### Enum Parameters

Enums used as parameters must conform to `AppEnum`:

```swift
enum ReminderPriority: String, AppEnum {
    case low
    case medium
    case high

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Priority")
    }

    static var caseDisplayRepresentations: [ReminderPriority: DisplayRepresentation] {
        [
            .low: "Low",
            .medium: "Medium",
            .high: "High"
        ]
    }
}
```

### Prefer Optional Parameters

An unset optional parameter never triggers a follow-up question — the intent acts immediately and degrades gracefully (WWDC24 10176). "Show Folder" with no folder set should open the folders list, giving the full in-app picking experience, rather than interrogating on every run.

Mark a parameter **required only when the intent is useless without it** (Search Mail's query text). Required means the user is asked a follow-up question you write (`requestValueDialog`) on every run — keep it concise and clear (WWDC24 10176, WWDC25 244).

Parameter type ladder (WWDC24 10176): built-in types for simple input (numbers, text, dates) → static `AppEnum` for fixed option sets (your app's tabs) → `AppEntity` dynamic parameters when options change over time (folders the user adds), so the option list stays current.

### Binary Intents Default to Toggle

Two-state set-intents must support a toggle value and default to it — otherwise every run interrogates "on or off?" (WWDC24 10176):

```swift
// ❌ Binary set-intent with no toggle default -- prompts on every run
@Parameter(title: "State") var state: FlashlightState        // .on / .off

// ✅ Toggle is a supported value AND the default -- runs without asking
@Parameter(title: "State", default: .toggle) var state: FlashlightState  // .on / .off / .toggle
```

### Parameter Summaries

Without a `parameterSummary`, essential parameters sit "below the fold" in Shortcuts. Provide a natural-language sentence embedding every essential parameter — and it must read as a grammatical sentence for **every possible parameter value combination**, both while browsing and while editing the parameter inline (WWDC24 10210, 10176):

```swift
static var parameterSummary: some ParameterSummary {
    Summary("Open \(\.$note)")
}
```

An intent's summary reads: app name → verb → parameters (WWDC24 10176). The summary is also a hard visibility gate for running intents from Spotlight on Mac — see `entities-spotlight.md`.

### Parameter Validation

Validate input inside `perform()` and throw an error with a user-facing dialog:

```swift
func perform() async throws -> some IntentResult & ProvidesDialog {
    guard !reminderTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
        throw $reminderTitle.needsValueError("Please provide a title for the reminder.")
    }

    guard reminderTitle.count <= 200 else {
        throw IntentError.custom(
            localizedDescription: "Title must be 200 characters or fewer."
        )
    }

    // proceed with valid input
    try await ReminderStore.shared.save(reminder)
    return .result(dialog: "Created: \(reminderTitle)")
}
```

## The perform() Method

`perform()` is the entry point when the intent runs. It must be `async throws` and return `some IntentResult`.

### Return Types

| Return Type | Use Case |
|-------------|----------|
| `.result()` | No output needed |
| `.result(dialog:)` | Spoken/displayed text |
| `.result(value:)` | Return a value for Shortcuts chaining |
| `.result(value:dialog:)` | Return value and speak dialog |
| `.result(view:)` | Show a SwiftUI snippet view |
| `.result(value:dialog:view:)` | All of the above |

### Returning a Value

When your intent produces output that another Shortcut can consume:

```swift
struct CountItemsIntent: AppIntent {
    static var title: LocalizedStringResource = "Count Items"

    @Parameter(title: "List")
    var list: ListEntity

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let count = await ListStore.shared.itemCount(for: list.id)
        return .result(value: count)
    }
}
```

### Error Handling in perform()

```swift
func perform() async throws -> some IntentResult & ProvidesDialog {
    do {
        let result = try await service.doWork()
        return .result(dialog: "Done: \(result.summary)")
    } catch ServiceError.notAuthenticated {
        throw IntentError.custom(
            localizedDescription: "Please sign in to your account first."
        )
    } catch ServiceError.networkUnavailable {
        throw IntentError.custom(
            localizedDescription: "No network connection. Please try again later."
        )
    } catch {
        throw IntentError.custom(
            localizedDescription: "Something went wrong. Please try again."
        )
    }
}
```

## App Shortcuts

App Shortcuts let users invoke intents with specific voice phrases without any setup.

### AppShortcutsProvider

```swift
struct MyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckBalanceIntent(),
            phrases: [
                "Check my balance in \(.applicationName)",
                "What's my \(.applicationName) balance"
            ],
            shortTitle: "Check Balance",
            systemImageName: "creditcard"
        )

        AppShortcut(
            intent: CreateReminderIntent(),
            phrases: [
                "Create a reminder in \(.applicationName)",
                "Add a \(.applicationName) reminder"
            ],
            shortTitle: "New Reminder",
            systemImageName: "plus.circle"
        )
    }
}
```

### Phrase Guidelines

Follow these rules for natural-sounding phrases:

```swift
// ✅ Good phrases -- natural, include app name placeholder
"Check my balance in \(.applicationName)"
"Start a workout with \(.applicationName)"
"Open \(.applicationName) settings"

// ❌ Bad phrases -- unnatural, missing app name, too generic
"Do the thing"                    // No app name, too vague
"Check balance"                   // Missing \(.applicationName)
"Please check my balance now"     // Overly conversational
```

Rules:
- Always include `\(.applicationName)` so the system binds the phrase to your app
- Keep phrases short and direct (3-8 words)
- Use natural sentence fragments users would actually say
- Provide 2-3 phrase variations per shortcut
- Avoid filler words like "please" or "now"

### Parameterized Phrases

Include parameters in voice phrases using entity references:

```swift
AppShortcut(
    intent: OpenNoteIntent(),
    phrases: [
        "Open \(\.$note) in \(.applicationName)",
        "Show my \(\.$note) note in \(.applicationName)"
    ],
    shortTitle: "Open Note",
    systemImageName: "doc.text"
)
```

The system resolves `\(\.$note)` by querying the entity's `defaultQuery` with what the user said.

### OpenIntent for Entities

When you have an entity type that users open or view, conform to `OpenIntent`:

```swift
struct OpenRecipeIntent: AppIntent, OpenIntent {
    static var title: LocalizedStringResource = "Open Recipe"

    @Parameter(title: "Recipe")
    var target: RecipeEntity

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NavigationState.shared.navigate(to: .recipe(id: target.id))
        }
        return .result()
    }
}
```

This enables "Open [recipe name] in [App Name]" automatically for all recipes.

`OpenIntent` defines the `target` parameter and **implies `openAppWhenRun`** — delete the explicit property (WWDC24 10210).

## Patterns

### ✅ Good Patterns

```swift
// Clear, descriptive title
static var title: LocalizedStringResource = "Add Item to Shopping List"

// Descriptive parameter titles
@Parameter(title: "Item Name")
var itemName: String

// Meaningful dialog responses
return .result(dialog: "Added \(itemName) to your shopping list.")

// Optional parameters with sensible defaults
@Parameter(title: "Quantity", default: 1)
var quantity: Int
```

### ❌ Anti-Patterns

```swift
// Vague title
static var title: LocalizedStringResource = "Do Action"

// Missing parameter title
@Parameter
var x: String

// Silent result when user expects feedback
return .result()  // User said "Add milk" and got no confirmation

// Blocking the main thread
func perform() async throws -> some IntentResult {
    let result = heavyComputation()  // Not async, blocks
    return .result(value: result)
}
```

## Complete Example: Task Manager

```swift
import AppIntents

// MARK: - Entity

struct TaskEntity: AppEntity {
    var id: String
    var title: String
    var isComplete: Bool
    var dueDate: Date?

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Task"),
            numericFormat: "\(placeholder: .int) tasks"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: isComplete ? "Completed" : "Pending"
        )
    }

    static var defaultQuery = TaskEntityQuery()
}

// MARK: - Entity Query

struct TaskEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [TaskEntity] {
        await TaskStore.shared.tasks(for: identifiers)
    }

    func entities(matching string: String) async throws -> [TaskEntity] {
        await TaskStore.shared.search(matching: string)
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        await TaskStore.shared.recentTasks(limit: 10)
    }
}

// MARK: - Intents

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description: IntentDescription = "Creates a new task"

    @Parameter(title: "Title")
    var taskTitle: String

    @Parameter(title: "Due Date")
    var dueDate: Date?

    func perform() async throws -> some IntentResult & ReturnsValue<TaskEntity> & ProvidesDialog {
        let task = try await TaskStore.shared.create(
            title: taskTitle,
            dueDate: dueDate
        )
        let entity = TaskEntity(
            id: task.id,
            title: task.title,
            isComplete: false,
            dueDate: task.dueDate
        )
        return .result(
            value: entity,
            dialog: "Created task: \(taskTitle)"
        )
    }
}

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description: IntentDescription = "Marks a task as complete"

    @Parameter(title: "Task")
    var task: TaskEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await TaskStore.shared.markComplete(id: task.id)
        return .result(dialog: "Marked \(task.title) as complete.")
    }
}

// MARK: - App Shortcuts

struct TaskShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task in \(.applicationName)",
                "Create a \(.applicationName) task"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Complete \(\.$task) in \(.applicationName)",
                "Mark \(\.$task) done in \(.applicationName)"
            ],
            shortTitle: "Complete Task",
            systemImageName: "checkmark.circle"
        )
    }
}
```

## References

- [AppIntent protocol](https://developer.apple.com/documentation/AppIntents/AppIntent)
- [App Shortcuts](https://developer.apple.com/documentation/AppIntents/app-shortcuts)
- [AppShortcutsProvider](https://developer.apple.com/documentation/AppIntents/AppShortcutsProvider)
- [AppEnum](https://developer.apple.com/documentation/AppIntents/AppEnum)
- [IntentDescription](https://developer.apple.com/documentation/AppIntents/IntentDescription)
