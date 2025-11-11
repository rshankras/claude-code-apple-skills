# iOS App Architecture Guide

Comprehensive guide to iOS architecture patterns, helping you choose the right architecture for your app.

## Architecture Pattern Overview

### Quick Comparison Table

| Pattern | Complexity | Learning Curve | Best For | Team Size | Testability |
|---------|-----------|----------------|----------|-----------|-------------|
| **MVVM** | Medium | Medium | Most apps | Any | High |
| **MVC** | Low | Low | Simple apps, prototypes | Solo-Small | Medium |
| **TCA** | High | High | Complex state, large apps | Medium-Large | Very High |
| **VIPER** | Very High | High | Enterprise apps | Large | Very High |
| **Redux-like** | High | Medium-High | Complex state management | Medium-Large | High |

## 1. MVVM (Model-View-ViewModel)

**Recommended for: Most iOS apps**

### Overview
MVVM is the de facto standard for modern iOS apps, especially with SwiftUI. It provides excellent separation of concerns while remaining practical and maintainable.

### Structure
```
Model
├── Data entities
├── Business logic
└── Data access

View
├── SwiftUI Views (or UIKit views)
├── UI presentation only
└── Binds to ViewModel

ViewModel
├── Presentation logic
├── State management
├── Transforms model data for view
└── Handles user actions
```

### When to Use MVVM

✅ **Use MVVM when:**
- Building a SwiftUI app (natural fit)
- Team is familiar with the pattern
- Need good testability without over-engineering
- App has moderate complexity
- Want balance between simplicity and structure

❌ **Avoid MVVM when:**
- App is extremely simple (plain MVC sufficient)
- Need complex state coordination (consider TCA)
- Team prefers different established pattern

### MVVM Example Structure

```swift
// Model
struct Expense {
    let id: UUID
    let title: String
    let amount: Decimal
    let date: Date
}

// ViewModel
@MainActor
class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: ExpenseRepository

    init(repository: ExpenseRepository) {
        self.repository = repository
    }

    func loadExpenses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            expenses = try await repository.fetchExpenses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteExpense(_ expense: Expense) async {
        do {
            try await repository.delete(expense)
            expenses.removeAll { $0.id == expense.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// View
struct ExpenseListView: View {
    @StateObject private var viewModel: ExpenseListViewModel

    init(repository: ExpenseRepository) {
        _viewModel = StateObject(wrappedValue: ExpenseListViewModel(repository: repository))
    }

    var body: some View {
        List(viewModel.expenses) { expense in
            ExpenseRow(expense: expense)
        }
        .task {
            await viewModel.loadExpenses()
        }
    }
}
```

### MVVM Best Practices
- ViewModels should be testable without UI
- Use dependency injection for ViewModels
- Keep Views dumb (minimal logic)
- One ViewModel per screen/feature (usually)
- ViewModels own business logic, Views own UI logic
- Use `@MainActor` for ViewModels with `@Published` properties

### Folder Structure for MVVM
```
MyApp/
├── Models/
│   ├── Expense.swift
│   └── Category.swift
├── ViewModels/
│   ├── ExpenseListViewModel.swift
│   └── ExpenseDetailViewModel.swift
├── Views/
│   ├── ExpenseListView.swift
│   ├── ExpenseDetailView.swift
│   └── Components/
│       └── ExpenseRow.swift
├── Services/
│   ├── ExpenseRepository.swift
│   └── NetworkService.swift
└── Utilities/
    └── Extensions.swift
```

## 2. MVC (Model-View-Controller)

**Recommended for: Simple apps, prototypes, UIKit apps**

### Overview
The classic pattern, built into UIKit. Despite its "Massive View Controller" reputation, it works well for simple apps when used properly.

### Structure
```
Model
├── Data entities
└── Business logic

View
├── UIView subclasses
└── Display only

Controller
├── UIViewController
├── Coordinates between Model and View
├── Handles user input
└── Often becomes large
```

### When to Use MVC

✅ **Use MVC when:**
- Building a simple app or prototype
- Working primarily with UIKit
- Team is most familiar with MVC
- Rapid development is priority
- App won't grow complex

❌ **Avoid MVC when:**
- App will be complex/large
- Need high testability
- Using SwiftUI (MVVM is better fit)
- Multiple developers working on same features

### MVC Best Practices
- Keep ViewControllers focused (under 300 lines)
- Extract logic into services/managers
- Use child view controllers to break up complexity
- Create reusable UIView components
- Use protocols for delegation

## 3. TCA (The Composable Architecture)

**Recommended for: Large, complex apps with sophisticated state management**

### Overview
A functional architecture from Point-Free, emphasizing composition, testability, and predictable state management. Inspired by Elm and Redux.

### Core Concepts
- **State**: Single source of truth
- **Action**: All possible events
- **Reducer**: Pure function that evolves state
- **Effect**: Side effects (network, database, etc.)
- **Store**: Holds state and processes actions

### When to Use TCA

✅ **Use TCA when:**
- Building a large, complex app
- Need predictable state management
- Want comprehensive testing
- Team is experienced or willing to learn
- Complex state coordination between features
- Want time-travel debugging

❌ **Avoid TCA when:**
- Building simple apps (overkill)
- Team unfamiliar and on tight timeline
- Need rapid prototyping
- Team size is very small

### TCA Example Structure

```swift
import ComposableArchitecture

// State
struct ExpenseListState: Equatable {
    var expenses: [Expense] = []
    var isLoading = false
    var errorMessage: String?
}

// Action
enum ExpenseListAction: Equatable {
    case loadExpenses
    case expensesLoaded(TaskResult<[Expense]>)
    case deleteExpense(Expense)
    case expenseDeleted(TaskResult<Void>)
}

// Environment (Dependencies)
struct ExpenseListEnvironment {
    var expenseRepository: ExpenseRepository
}

// Reducer
let expenseListReducer = Reducer<
    ExpenseListState,
    ExpenseListAction,
    ExpenseListEnvironment
> { state, action, environment in
    switch action {
    case .loadExpenses:
        state.isLoading = true
        return environment.expenseRepository
            .fetchExpenses()
            .catchToEffect(ExpenseListAction.expensesLoaded)

    case .expensesLoaded(.success(let expenses)):
        state.isLoading = false
        state.expenses = expenses
        return .none

    case .expensesLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

    case .deleteExpense(let expense):
        return environment.expenseRepository
            .delete(expense)
            .catchToEffect { .expenseDeleted($0) }

    case .expenseDeleted(.success):
        return .none

    case .expenseDeleted(.failure(let error)):
        state.errorMessage = error.localizedDescription
        return .none
    }
}

// View
struct ExpenseListView: View {
    let store: Store<ExpenseListState, ExpenseListAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            List(viewStore.expenses) { expense in
                ExpenseRow(expense: expense)
            }
            .task {
                viewStore.send(.loadExpenses)
            }
        }
    }
}
```

### TCA Best Practices
- Keep reducers pure (no side effects)
- Use dependencies for testability
- Compose features with reducer composition
- Leverage exhaustive testing
- Use `@Dependency` for dependencies

### Resources for TCA
- [Point-Free TCA Repository](https://github.com/pointfreeco/swift-composable-architecture)
- [Point-Free Videos](https://www.pointfree.co)

## 4. VIPER

**Recommended for: Enterprise apps, large teams**

### Overview
Highly modular pattern that separates concerns into five components. Provides excellent testability and separation but adds significant complexity.

### Structure
```
View
├── Displays data
└── Minimal logic

Interactor
├── Business logic
└── Data operations

Presenter
├── Formats data for view
└── Handles view logic

Entity
├── Data models
└── Plain structs

Router
├── Navigation logic
└── Screen transitions
```

### When to Use VIPER

✅ **Use VIPER when:**
- Building enterprise-scale apps
- Large team working on same codebase
- Maximum testability required
- Clear separation of responsibilities critical
- Long-term maintenance expected

❌ **Avoid VIPER when:**
- Small to medium apps
- Solo developer or small team
- Rapid development needed
- Team unfamiliar with pattern

### VIPER Considerations
- High boilerplate (5 files per screen)
- Steep learning curve
- Slower initial development
- Excellent for large, long-lived apps
- Overkill for most apps

## 5. Redux-like / Flux

**Recommended for: Apps needing centralized state management**

### Overview
Unidirectional data flow with centralized state store. Similar to TCA but more lightweight.

### Core Concepts
- Single state tree
- Actions dispatched to change state
- Reducers handle state changes
- Middleware for side effects

### When to Use Redux-like

✅ **Use when:**
- Need centralized state management
- Want predictable state updates
- Complex state coordination
- Time-travel debugging desired
- Team familiar with Redux

❌ **Avoid when:**
- Simple local state sufficient
- Team unfamiliar with pattern
- Prefer less boilerplate

### Popular Swift Redux Libraries
- ReSwift
- SwiftRex
- Suas

## Architecture Decision Framework

### Step 1: Assess Your Project

**Project Size:**
- Small (<10 screens): MVC or MVVM
- Medium (10-30 screens): MVVM
- Large (30+ screens): MVVM or TCA
- Enterprise: VIPER or TCA

**Team Size:**
- Solo: MVVM or MVC
- 2-5 developers: MVVM
- 5-10 developers: MVVM or TCA
- 10+ developers: TCA or VIPER

**Complexity:**
- Simple CRUD: MVC or MVVM
- Moderate business logic: MVVM
- Complex state management: TCA
- Complex business rules: VIPER or TCA

### Step 2: Consider Constraints

**Timeline:**
- Tight deadline: MVC or MVVM
- Standard timeline: MVVM
- Long-term project: Any

**Team Experience:**
- Junior team: MVC or MVVM
- Mixed experience: MVVM
- Senior team: Any

**UI Framework:**
- SwiftUI: MVVM or TCA (best fits)
- UIKit: Any (MVC is native)
- Hybrid: MVVM (most flexible)

### Step 3: Choose Architecture

Based on the assessment, follow this decision tree:

```
Is the app simple (<10 screens, basic features)?
├─ Yes → Use MVC or MVVM
└─ No → Continue

Does the app have complex state management needs?
├─ Yes → Use TCA or Redux-like
└─ No → Continue

Is the team large (10+ developers)?
├─ Yes → Use VIPER or TCA
└─ No → Continue

Using SwiftUI?
├─ Yes → Use MVVM
└─ No (UIKit) → Use MVC or MVVM

Default: MVVM (best balance for most apps)
```

## Hybrid Approaches

### MVVM + Coordinators
Adds navigation coordination to MVVM:
- ViewModels focus on presentation logic
- Coordinators handle navigation flow
- Better separation of concerns
- Good for medium-large apps

### Clean Architecture + MVVM
Adds layer separation to MVVM:
- Domain layer (business logic)
- Data layer (repositories, APIs)
- Presentation layer (MVVM)
- Enterprise-grade separation

## Common Pitfalls

### ❌ Over-Engineering
**Problem**: Using VIPER for a simple to-do app
**Solution**: Match architecture to actual complexity

### ❌ Under-Engineering
**Problem**: Large app with no architecture
**Solution**: Introduce structure early, refactor if needed

### ❌ Mixing Patterns
**Problem**: MVVM + MVC + VIPER in same codebase
**Solution**: Choose one pattern and stick to it

### ❌ Ignoring Team
**Problem**: Using TCA when team is unfamiliar
**Solution**: Consider team experience and learning curve

### ❌ Architecture Astronauting
**Problem**: Creating custom architecture "better than all others"
**Solution**: Use proven patterns, customize minimally

## Migration Strategies

### From MVC to MVVM
1. Start with new features in MVVM
2. Gradually extract logic from ViewControllers
3. Create ViewModels for existing screens
4. Refactor incrementally

### From MVVM to TCA
1. Identify complex state management areas
2. Migrate feature-by-feature
3. Use MVVM/TCA hybrid during transition
4. Complete migration when team comfortable

## Recommendations by App Type

### Personal Productivity App
**Recommended**: MVVM
**Rationale**: Good balance, excellent SwiftUI support

### Social Media App
**Recommended**: TCA or MVVM+Coordinators
**Rationale**: Complex state, many navigation flows

### E-Commerce App
**Recommended**: MVVM or TCA
**Rationale**: Moderate complexity, good testability needed

### Enterprise B2B App
**Recommended**: VIPER or TCA
**Rationale**: Large codebase, multiple teams, high testability

### Game/Entertainment App
**Recommended**: MVC or custom
**Rationale**: Different patterns often needed

### Utility/Tool App
**Recommended**: MVVM
**Rationale**: Simple, focused, good structure

## Testing Considerations

### MVVM Testing
```swift
@MainActor
final class ExpenseListViewModelTests: XCTestCase {
    func testLoadExpenses() async {
        let mockRepo = MockExpenseRepository()
        mockRepo.expenses = [Expense(id: UUID(), title: "Test", amount: 10, date: Date())]

        let viewModel = ExpenseListViewModel(repository: mockRepo)
        await viewModel.loadExpenses()

        XCTAssertEqual(viewModel.expenses.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

### TCA Testing
```swift
@MainActor
final class ExpenseListTests: XCTestCase {
    func testLoadExpenses() async {
        let store = TestStore(
            initialState: ExpenseListState(),
            reducer: expenseListReducer,
            environment: .mock
        )

        await store.send(.loadExpenses) {
            $0.isLoading = true
        }

        await store.receive(.expensesLoaded(.success([...]))) {
            $0.isLoading = false
            $0.expenses = [...]
        }
    }
}
```

## Resources

### Books
- [Advanced iOS App Architecture](https://www.raywenderlich.com/books/advanced-ios-app-architecture)
- [iOS Design Patterns](https://www.raywenderlich.com/books/design-patterns-by-tutorials)

### Online Resources
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Point-Free (TCA)](https://www.pointfree.co)
- [objc.io Architecture Articles](https://www.objc.io)

### Apple Documentation
- [App Architecture](https://developer.apple.com/documentation/xcode/app-architecture)
- [SwiftUI Architecture](https://developer.apple.com/documentation/swiftui)

## Summary

**For most iOS apps: Use MVVM**
- Proven pattern
- Excellent SwiftUI support
- Good testability
- Manageable complexity
- Strong community support

**Use TCA when:**
- Complex state management
- Large app
- Experienced team
- Need predictable state

**Use MVC when:**
- Simple app
- Rapid prototype
- UIKit-focused

**Use VIPER when:**
- Enterprise scale
- Large team
- Maximum separation needed

**Default recommendation: Start with MVVM, evaluate if needs change**
