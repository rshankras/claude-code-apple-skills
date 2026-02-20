# App Intents Basics

Core patterns for the AppIntent protocol, parameters, the `perform()` method, and App Shortcuts with voice phrases.

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

    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NavigationState.shared.navigate(to: .recipe(id: target.id))
        }
        return .result()
    }
}
```

This enables "Open [recipe name] in [App Name]" automatically for all recipes.

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
