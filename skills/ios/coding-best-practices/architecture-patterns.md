# Architecture Patterns

Best practices for MVVM architecture, code organization, and memory management.

## MVVM Architecture

### Core Principles

**Model**: Pure data structures (Core Data entities, structs)
**View**: SwiftUI views - presentation only
**ViewModel**: Business logic, data operations, state management

### Anti-patterns

```swift
// ❌ Business logic in View
struct ExpenseView: View {
    @State var expenses: [Expense] = []

    var body: some View {
        VStack {
            Button("Calculate") {
                // Complex calculation logic here
                let total = expenses.reduce(0) { $0 + $1.amount }
                // Save to Core Data here
            }
        }
    }
}

// ❌ UI logic in ViewModel
class ExpenseViewModel: ObservableObject {
    func getBackgroundColor() -> Color {
        return isValid ? .green : .red
    }
}
```

### Good patterns

```swift
// ✅ Clean View
struct ExpenseView: View {
    @StateObject private var viewModel: ExpenseViewModel

    var body: some View {
        VStack {
            Button("Calculate") {
                viewModel.calculateTotal()
            }
        }
        .background(isValidColor)
    }

    private var isValidColor: Color {
        viewModel.isValid ? .green : .red
    }
}

// ✅ ViewModel with business logic
class ExpenseViewModel: ObservableObject {
    @Published var totalAmount: Double = 0
    @Published var isValid: Bool = false

    func calculateTotal() {
        totalAmount = expenses.reduce(0) { $0 + $1.amount }
        isValid = totalAmount > 0
    }
}
```

### Responsibilities

**Views Should:**
- Render UI
- Handle user input events
- Bind to ViewModel state
- Apply UI styling and layout

**Views Should NOT:**
- Perform business logic
- Access data layer directly
- Calculate derived values
- Make network/database calls

**ViewModels Should:**
- Contain business logic
- Manage state
- Validate data
- Coordinate data operations
- Transform data for presentation

**ViewModels Should NOT:**
- Reference UIKit/SwiftUI types (Color, Font, etc.)
- Perform UI layout
- Handle navigation directly

### Checklist
- [ ] Views only handle presentation
- [ ] ViewModels contain business logic
- [ ] Models are pure data structures
- [ ] No business logic in Views
- [ ] No UI code in ViewModels
- [ ] Clear separation of concerns

## Code Organization

### File Structure

```swift
// ✅ Organized with marks
class ExpenseViewModel: ObservableObject {

    // MARK: - Properties

    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var totalAmount: Double = 0
    private var isLoading: Bool = false

    // MARK: - Initialization

    init() {
        loadExpenses()
    }

    // MARK: - Public Methods

    func addExpense(_ expense: Expense) { }
    func deleteExpense(_ expense: Expense) { }

    // MARK: - Private Methods

    private func loadExpenses() { }
    private func calculateTotal() { }
}

// ✅ Extensions for protocols
extension ExpenseViewModel: UITableViewDelegate {
    // Delegate methods
}
```

### Access Control

```swift
// ❌ Public everything
class ExpenseViewModel {
    var expenses: [Expense] = []
    var totalAmount: Double = 0
    var isLoading: Bool = false
}

// ✅ Private by default
class ExpenseViewModel {
    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var totalAmount: Double = 0
    private var isLoading: Bool = false
}
```

### Common MARK Sections

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Actions
// MARK: - Helpers
// MARK: - Constants
```

### Checklist
- [ ] Logical grouping with `// MARK: -`
- [ ] Private by default
- [ ] Consistent ordering (properties → lifecycle → methods)
- [ ] Extensions for protocol conformance
- [ ] Clear file naming

## Memory Management

### Retain Cycles

### Anti-patterns

```swift
// ❌ Retain cycle
class ExpenseViewModel {
    var onComplete: (() -> Void)?

    func loadData() {
        dataService.fetch { data in
            self.onComplete?() // Potential retain cycle
        }
    }
}

// ❌ Delegate retain cycle
class MyView {
    var delegate: MyDelegate // Should be weak
}
```

### Good patterns

```swift
// ✅ Weak self
func loadData() {
    dataService.fetch { [weak self] data in
        guard let self = self else { return }
        self.process(data)
    }
}

// ✅ Weak delegate
protocol ExpenseViewModelDelegate: AnyObject { }

class ExpenseViewModel {
    weak var delegate: ExpenseViewModelDelegate?
}

// ✅ Unowned for guaranteed non-nil
class ExpenseView {
    unowned let parentController: UIViewController
}
```

### Closure Capture Rules

```swift
// ✅ Use [weak self] when:
// - Self might be deallocated before closure completes
// - Async operations (network, timers)
// - Escaping closures

// ✅ Use [unowned self] when:
// - Self is guaranteed to exist
// - Closure lifecycle tied to self

// ✅ No capture needed when:
// - Non-escaping closures
// - Static context
// - No reference to self
```

### Checklist
- [ ] Use `[weak self]` in closures when needed
- [ ] Avoid retain cycles with delegates (use `weak`)
- [ ] Be careful with `@escaping` closures
- [ ] Use value types (structs) where appropriate
- [ ] Cancel tasks/subscriptions in deinit

## Dependency Injection

### Anti-patterns

```swift
// ❌ Hard to test
class ExpenseViewModel {
    func save() {
        CoreDataStack.sharedInstance.save()
    }
}
```

### Good patterns

```swift
// ✅ Testable with dependency injection
protocol DataStore {
    func save() throws
}

class ExpenseViewModel {
    private let dataStore: DataStore

    init(dataStore: DataStore = CoreDataStack.sharedInstance) {
        self.dataStore = dataStore
    }

    func save() {
        try? dataStore.save()
    }
}

// ✅ For testing
class MockDataStore: DataStore {
    var saveCallCount = 0

    func save() throws {
        saveCallCount += 1
    }
}
```

### Benefits
- **Testability**: Easy to mock dependencies
- **Flexibility**: Swap implementations
- **Decoupling**: Reduce direct dependencies
- **Clarity**: Explicit dependencies

### Checklist
- [ ] Protocol-based dependencies
- [ ] Inject dependencies via initializer
- [ ] Provide default implementations
- [ ] Avoid singletons (or make them injectable)

## Security & Privacy

### Sensitive Data

```swift
// ❌ Bad practices
let apiKey = "sk_live_abc123..." // Hardcoded
UserDefaults.standard.set(password, forKey: "password") // Insecure storage

// ✅ Good practices
// Use environment variables or configuration files
let apiKey = ProcessInfo.processInfo.environment["API_KEY"]

// Use Keychain for sensitive data
KeychainManager.save(password, for: "userPassword")
```

### Input Validation

```swift
// ✅ Always validate user input
func saveExpense(amount: String) throws {
    guard let amountValue = Double(amount), amountValue > 0 else {
        throw ValidationError.invalidAmount
    }
    // ...
}
```

### Logging

```swift
// ❌ Don't log sensitive data
print("User password: \(password)")
print("Credit card: \(creditCard)")

// ✅ Log safely
print("User authenticated: \(user.id)")
print("Payment processed: ***")
```

### Checklist
- [ ] No hardcoded credentials or API keys
- [ ] Sensitive data in Keychain, not UserDefaults
- [ ] Use HTTPS for network requests
- [ ] Validate user input
- [ ] Avoid logging sensitive data

## File Organization Best Practices

### Project Structure

```
EasySplit/
├── Models/           # Core Data entities, data models
├── ViewModels/       # ViewModels for each feature
├── Views/            # SwiftUI views
│   ├── Main/
│   ├── Expense/
│   ├── Group/
│   └── Settings/
├── Services/         # Core Data, networking, etc.
├── Utilities/        # Helpers, extensions
└── Resources/        # Assets, localization
```

### Naming Conventions

- **Views**: `ExpenseListView.swift`, `AddExpenseView.swift`
- **ViewModels**: `ExpenseViewModel.swift`, `GroupViewModel.swift`
- **Models**: `Expense.swift`, `Group.swift`
- **Protocols**: `DataStore.swift`, `Loadable.swift`
- **Extensions**: `String+Extensions.swift`, `Date+Formatting.swift`

## References

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
- [Automatic Reference Counting](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)
