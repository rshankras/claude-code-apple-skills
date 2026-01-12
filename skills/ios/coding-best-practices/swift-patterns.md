# Swift Language Patterns

Quick reference for Swift language best practices and idioms.

## Optionals Handling

### Anti-patterns

```swift
// ❌ Force unwrapping
let name = user.userName!

// ❌ Nested if lets (pyramid of doom)
if let user = user {
    if let name = user.userName {
        if let email = user.email {
            // ...
        }
    }
}

// ❌ Unnecessary optional chaining
if expense?.amount != nil {
    let amount = expense!.amount
}
```

### Good patterns

```swift
// ✅ Nil coalescing
let name = user.userName ?? "Unknown"

// ✅ Guard for early return
guard let user = expense.payer else { return }

// ✅ Combined guard
guard let user = expense.payer,
      let name = user.userName,
      !name.isEmpty else { return }

// ✅ Optional chaining
let upperName = user?.userName?.uppercased()
```

### Checklist
- [ ] Avoid force unwrapping (`!`) unless crash is intentional
- [ ] Use optional chaining (`?.`) and nil coalescing (`??`)
- [ ] Prefer `guard let` for early returns
- [ ] Use `if let` for conditional unwrapping
- [ ] Avoid pyramid of doom with multiple `if let`

## Type Safety & Enums

### Anti-patterns

```swift
// ❌ String constants
if category == "Food" { }

// ❌ Magic numbers
if status == 0 { }

// ❌ If-else chains for enums
if category == .food {
} else if category == .transport {
} else if category == .entertainment {
}
```

### Good patterns

```swift
// ✅ Enum with raw values
enum ExpenseCategory: String, CaseIterable {
    case food = "Food"
    case transport = "Transport"
    case entertainment = "Entertainment"
}

// ✅ Switch with exhaustive checking
switch category {
case .food:
    // ...
case .transport:
    // ...
case .entertainment:
    // ...
}

// ✅ Associated values
enum NetworkResult {
    case success(data: Data)
    case failure(error: Error)
}
```

### Checklist
- [ ] Use enums instead of string/int constants
- [ ] Avoid stringly-typed code
- [ ] Use associated values for related data
- [ ] Prefer `switch` over multiple `if` for enums
- [ ] Use `CaseIterable` when appropriate

## Collections & Sequences

### Anti-patterns

```swift
// ❌ Manual loop for transformation
var names: [String] = []
for user in users {
    names.append(user.name)
}

// ❌ Inefficient filtering
let found = users.filter { $0.id == userId }.first

// ❌ Force array access
let first = array[0]

// ❌ Count comparison
if array.count == 0 { }
```

### Good patterns

```swift
// ✅ Map for transformation
let names = users.map { $0.name }

// ✅ CompactMap for optional unwrapping
let names = users.compactMap { $0.userName }

// ✅ First(where:) for finding
let found = users.first { $0.id == userId }

// ✅ Safe array access
guard let first = array.first else { return }

// ✅ isEmpty
if array.isEmpty { }
```

### Checklist
- [ ] Use `map`, `filter`, `reduce` instead of loops where appropriate
- [ ] Prefer `compactMap` over `map` + filter nil
- [ ] Use `first(where:)` instead of `filter().first`
- [ ] Avoid force-accessing arrays with `[0]`
- [ ] Use `isEmpty` instead of `count == 0`

## Error Handling

### Anti-patterns

```swift
// ❌ Silent failure
try? context.save()

// ❌ Generic error handling
do {
    try something()
} catch {
    print("Error")
}

// ❌ Boolean success flags
func saveData() -> Bool {
    // ...
}
```

### Good patterns

```swift
// ✅ Custom errors
enum DataError: LocalizedError {
    case saveFailed
    case invalidData(reason: String)

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        }
    }
}

// ✅ Proper error propagation
func saveExpense() throws {
    guard !name.isEmpty else {
        throw DataError.invalidData(reason: "Name is empty")
    }
    try context.save()
}

// ✅ Result type
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // ...
}
```

### Checklist
- [ ] Use Swift error handling (`throws`, `try`, `catch`)
- [ ] Define custom error types
- [ ] Avoid swallowing errors silently
- [ ] Use `Result` type for async operations
- [ ] Provide meaningful error messages

## Naming Conventions

### Anti-patterns

```swift
// ❌ Unclear names
var e: Expense
func calc() { }
var flg: Bool

// ❌ Redundant names
func calculateCalculation() { }
var nameString: String

// ❌ Poor boolean names
var active: Bool
var valid: Bool
```

### Good patterns

```swift
// ✅ Clear names
var currentExpense: Expense
func calculateTotal() { }
var isActive: Bool

// ✅ Descriptive methods
func saveExpense(named: String, amount: Double)
func deleteExpense(_ expense: Expense)

// ✅ Boolean clarity
var isActive: Bool
var hasValidData: Bool
var shouldShowAlert: Bool
```

### Checklist
- [ ] Clear, descriptive names
- [ ] Boolean names start with `is`, `has`, `should`
- [ ] Method names describe action
- [ ] Avoid abbreviations
- [ ] Follow Swift API Design Guidelines

## References

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift.org Documentation](https://docs.swift.org/)
