# SwiftUI Patterns

Quick reference for SwiftUI best practices and common patterns.

## State Management

### Anti-patterns

```swift
// ❌ ObservedObject for view-owned
@ObservedObject var viewModel = MyViewModel()

// ❌ State for complex objects
@State var viewModel = MyViewModel()

// ❌ Multiple sources of truth
@State var name = ""
var expense: Expense
```

### Good patterns

```swift
// ✅ StateObject for view-owned
@StateObject private var viewModel = MyViewModel()

// ✅ ObservedObject for passed
@ObservedObject var viewModel: MyViewModel

// ✅ Binding for child-parent connection
@Binding var isPresented: Bool

// ✅ Single source of truth
@State private var name = ""
// OR
@ObservedObject var expense: Expense
```

### When to Use Each Property Wrapper

| Wrapper | Use Case | Ownership |
|---------|----------|-----------|
| `@State` | Simple value types (String, Int, Bool) | View owns |
| `@StateObject` | ObservableObject (ViewModels) | View owns |
| `@ObservedObject` | ObservableObject passed from parent | Parent owns |
| `@EnvironmentObject` | Shared data across view hierarchy | App/Scene owns |
| `@Binding` | Two-way connection to parent state | Parent owns |

### Checklist
- [ ] Use `@State` for view-local state
- [ ] Use `@StateObject` for view-owned objects
- [ ] Use `@ObservedObject` for passed objects
- [ ] Use `@EnvironmentObject` for shared data
- [ ] Use `@Binding` for two-way connections
- [ ] Avoid `@ObservedObject` when should be `@StateObject`

## View Composition

### Anti-patterns

```swift
// ❌ Massive view body
var body: some View {
    VStack {
        // 200 lines of code
    }
}

// ❌ Complex logic in view
var body: some View {
    let filtered = items.filter { $0.isActive }
    let sorted = filtered.sorted { $0.date > $1.date }
    let grouped = Dictionary(grouping: sorted) { $0.category }
    // ...
}
```

### Good patterns

```swift
// ✅ Extracted subviews
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}

private var headerView: some View { /* ... */ }

// ✅ Separate view components
struct ExpenseRow: View {
    let expense: Expense
    var body: some View { /* ... */ }
}

// ✅ Logic in ViewModel or computed property
var sortedExpenses: [Expense] {
    viewModel.getSortedExpenses()
}
```

### Checklist
- [ ] Break large views into smaller components
- [ ] Use `@ViewBuilder` for conditional views
- [ ] Avoid heavy computation in `body`
- [ ] Extract subviews for reusability
- [ ] Keep view structs focused (Single Responsibility)

## Performance

### Anti-patterns

```swift
// ❌ Creating objects in body
var body: some View {
    let formatter = DateFormatter() // Created every render!
    Text(formatter.string(from: date))
}

// ❌ Heavy computation without caching
var body: some View {
    let total = expenses.reduce(0) { $0 + $1.amount }
    Text("Total: \(total)")
}
```

### Good patterns

```swift
// ✅ Static/cached formatters
static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

// ✅ Computed in ViewModel
var totalAmount: Double {
    viewModel.totalAmount
}

// ✅ Use @State for computed values
@State private var totalAmount: Double = 0

var body: some View {
    Text("Total: \(totalAmount)")
        .onAppear {
            totalAmount = viewModel.calculateTotal()
        }
}
```

### Checklist
- [ ] Use `Equatable` for complex view data
- [ ] Avoid creating ViewModels in `body`
- [ ] Use `id()` modifier carefully
- [ ] Minimize `@State` changes
- [ ] Avoid unnecessary view updates
- [ ] Cache expensive formatters and computations

## Common SwiftUI Patterns

### Conditional Views

```swift
// ✅ Using @ViewBuilder
@ViewBuilder
var content: some View {
    if isLoading {
        ProgressView()
    } else if hasError {
        ErrorView()
    } else {
        ContentView()
    }
}
```

### List Performance

```swift
// ✅ Provide stable IDs
List(expenses, id: \.id) { expense in
    ExpenseRow(expense: expense)
}

// ✅ For dynamic lists
List {
    ForEach(expenses) { expense in
        ExpenseRow(expense: expense)
    }
    .onDelete(perform: deleteExpenses)
}
```

### Form Handling

```swift
// ✅ Clean form structure
Form {
    Section("Details") {
        TextField("Name", text: $name)
        TextField("Amount", value: $amount, format: .currency(code: "USD"))
    }

    Section("Options") {
        Toggle("Is Paid", isOn: $isPaid)
        Picker("Category", selection: $category) {
            ForEach(ExpenseCategory.allCases) { category in
                Text(category.rawValue).tag(category)
            }
        }
    }
}
```

### Navigation

```swift
// ✅ NavigationStack (iOS 16+)
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item: item)
    }
}

// ✅ Sheet presentation
.sheet(isPresented: $showingSheet) {
    AddItemView()
}

// ✅ Alert presentation
.alert("Delete Item?", isPresented: $showingAlert) {
    Button("Delete", role: .destructive) {
        deleteItem()
    }
    Button("Cancel", role: .cancel) { }
}
```

## Memory Management in SwiftUI

### Closures in ViewModels

```swift
// ✅ Weak self in escaping closures
func loadData() {
    dataService.fetch { [weak self] data in
        guard let self = self else { return }
        self.process(data)
    }
}
```

### Task Cancellation

```swift
// ✅ Proper task lifecycle
.task {
    await viewModel.loadData()
}
// Automatically cancelled when view disappears

// ✅ Manual task management
@State private var dataTask: Task<Void, Never>?

var body: some View {
    ContentView()
        .onAppear {
            dataTask = Task {
                await loadData()
            }
        }
        .onDisappear {
            dataTask?.cancel()
        }
}
```

## References

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui)
- [Thinking in SwiftUI](https://www.objc.io/books/thinking-in-swiftui/)
