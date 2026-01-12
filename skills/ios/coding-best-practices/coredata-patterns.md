# Core Data Patterns

Best practices for working with Core Data in iOS applications.

## Context Management

### Anti-patterns

```swift
// ❌ Creating new contexts
let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

// ❌ Multiple contexts without coordination
let context1 = persistentContainer.viewContext
let context2 = persistentContainer.newBackgroundContext()
// Using both without proper synchronization
```

### Good patterns

```swift
// ✅ Use shared context
let context = CoreDataStack.sharedInstance.managedObjectContext

// ✅ Background context for heavy operations
let backgroundContext = CoreDataStack.sharedInstance.newBackgroundContext()
backgroundContext.perform {
    // Heavy work here
    try? backgroundContext.save()
}
```

### Checklist
- [ ] Always use single shared context for UI operations
- [ ] Use background contexts for batch operations
- [ ] Coordinate context changes with notifications
- [ ] Not creating new contexts unnecessarily

## Saving Data

### Anti-patterns

```swift
// ❌ Saving without checking
try? context.save()

// ❌ Saving in a loop
for user in users {
    let expense = Expense(context: context)
    expense.name = user.name
    try? context.save() // Inefficient!
}

// ❌ Silent failures
do {
    try context.save()
} catch {
    // Ignoring error
}
```

### Good patterns

```swift
// ✅ Check before saving
if context.hasChanges {
    do {
        try context.save()
    } catch {
        print("Save failed: \(error.localizedDescription)")
        // Handle error appropriately
    }
}

// ✅ Batch operations
for user in users {
    let expense = Expense(context: context)
    expense.name = user.name
}
// Save once after all changes
if context.hasChanges {
    try? context.save()
}

// ✅ Proper error handling
func saveContext() throws {
    guard context.hasChanges else { return }
    try context.save()
}
```

### Save Checklist
- [ ] Check `hasChanges` before saving
- [ ] Handle save errors properly
- [ ] Batch multiple changes before saving
- [ ] Use proper error handling, not `try?`

## Fetching Data

### Anti-patterns

```swift
// ❌ Untyped fetch
let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")

// ❌ Fetching all data
let expenses = try? context.fetch(request)

// ❌ String-based sorting
let sort = NSSortDescriptor(key: "date", ascending: true)
```

### Good patterns

```swift
// ✅ Typed fetch
let request: NSFetchRequest<Expense> = Expense.fetchRequest()

// ✅ Use predicates to filter
request.predicate = NSPredicate(format: "amount > %f", 100.0)

// ✅ Use sort descriptors
request.sortDescriptors = [
    NSSortDescriptor(keyPath: \Expense.date, ascending: false)
]

// ✅ Limit results if needed
request.fetchLimit = 50

// ✅ Fetch with error handling
do {
    let expenses = try context.fetch(request)
    return expenses
} catch {
    print("Fetch failed: \(error.localizedDescription)")
    return []
}
```

### Predicate Examples

```swift
// Simple comparison
NSPredicate(format: "amount > %f", 100.0)

// String matching
NSPredicate(format: "name CONTAINS[cd] %@", searchText)

// Date filtering
NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)

// Relationship filtering
NSPredicate(format: "group.name == %@", groupName)

// Multiple conditions
NSPredicate(format: "amount > %f AND category == %@", 50.0, category)

// IN operator
NSPredicate(format: "category IN %@", categories)

// Compound predicates
let predicate1 = NSPredicate(format: "amount > %f", 100.0)
let predicate2 = NSPredicate(format: "isPaid == YES")
let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
```

### Fetch Checklist
- [ ] Use typed fetch requests
- [ ] Apply predicates to filter data
- [ ] Use sort descriptors for ordering
- [ ] Set fetch limits for large datasets
- [ ] Handle fetch errors properly

## Property Access

### Anti-patterns

```swift
// ❌ Force unwrapping managed objects
let name = expense.name!
let amount = expense.amount!

// ❌ Not checking for nil
func displayExpense(_ expense: Expense) {
    label.text = expense.name // Might be nil
}
```

### Good patterns

```swift
// ✅ Safe property access
let name = expense.name ?? "Untitled"
let amount = expense.amount ?? 0.0

// ✅ Guard for required properties
guard let name = expense.name, !name.isEmpty else {
    print("Expense has no name")
    return
}

// ✅ Provide defaults in Core Data model
// Set default values in .xcdatamodeld editor
```

### Checklist
- [ ] Avoid force unwrapping Core Data properties
- [ ] Provide default values in model
- [ ] Use nil coalescing for optional properties
- [ ] Guard for required properties

## Relationships & Cascade Rules

### Delete Rules

```swift
// In .xcdatamodeld editor:

// Cascade: Delete related objects
Group -> Expense (Cascade)
// When group deleted, all expenses deleted

// Nullify: Set relationship to nil
Expense -> Payer (Nullify)
// When user deleted, expense.payer = nil

// Deny: Prevent deletion if relationship exists
Group -> User (Deny)
// Can't delete group if it has users

// No Action: Do nothing (use carefully!)
```

### Using Relationships

```swift
// ✅ Access relationships safely
if let expenses = group.expenses as? Set<Expense> {
    let sortedExpenses = expenses.sorted { $0.date ?? Date() > $1.date ?? Date() }
}

// ✅ Add to relationships
group.addToExpenses(expense)

// ✅ Remove from relationships
group.removeFromExpenses(expense)

// ✅ Fetching with relationship predicates
let request: NSFetchRequest<Expense> = Expense.fetchRequest()
request.predicate = NSPredicate(format: "group.name == %@", "Trip to Paris")
```

### Checklist
- [ ] Use appropriate cascade delete rules
- [ ] Access relationships safely
- [ ] Use Core Data's relationship methods
- [ ] Consider relationship cardinality

## Performance Optimization

### Batch Operations

```swift
// ✅ Batch delete
let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Expense.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "date < %@", oldDate as NSDate)

let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
try? context.execute(batchDelete)

// ✅ Batch update
let batchUpdate = NSBatchUpdateRequest(entityName: "Expense")
batchUpdate.predicate = NSPredicate(format: "isPaid == NO")
batchUpdate.propertiesToUpdate = ["isPaid": true]
try? context.execute(batchUpdate)
```

### Faulting

```swift
// ✅ Prefetch relationships
let request: NSFetchRequest<Group> = Group.fetchRequest()
request.relationshipKeyPathsForPrefetching = ["expenses", "users"]
let groups = try? context.fetch(request)

// ✅ Return faults for IDs only
request.returnsObjectsAsFaults = true
```

### Fetch Performance

```swift
// ✅ Fetch only what you need
request.propertiesToFetch = ["name", "amount"]
request.resultType = .dictionaryResultType

// ✅ Use fetch batching
request.fetchBatchSize = 20
```

### Checklist
- [ ] Use batch operations for mass updates/deletes
- [ ] Prefetch relationships when needed
- [ ] Limit fetch results
- [ ] Use fetch batching for large datasets
- [ ] Perform heavy operations on background context

## CloudKit Integration

### Checking Share Status

```swift
// ✅ Check if shared
let isShared = CoreDataStack.sharedInstance.isShared(object: group)

// ✅ Check edit permissions
let canEdit = CoreDataStack.sharedInstance.canEdit(object: group)

// ✅ Check ownership
let isOwner = CoreDataStack.sharedInstance.isOwner(object: group)

// ✅ Get share
if let share = CoreDataStack.sharedInstance.getShare(group) {
    // Work with CKShare
}
```

### Sharing Objects

```swift
// ✅ Share a group
if let share = try? CoreDataStack.sharedInstance.shareObject(
    group,
    to: share
) {
    // Present share controller
}

// ✅ Stop sharing
try? CoreDataStack.sharedInstance.stopSharing(group)
```

### Checklist
- [ ] Always check `isShared()` before operations
- [ ] Verify `canEdit()` for shared objects
- [ ] Handle share conflicts gracefully
- [ ] Test sync scenarios thoroughly

## Debugging

### Enable Logging

```swift
// ✅ SQL debug logging
// In scheme: -com.apple.CoreData.SQLDebug 1

// ✅ CloudKit logging
UserDefaults.standard.set(true, forKey: "EnableCloudKitLogs")

// ✅ Migration logging
// In scheme: -com.apple.CoreData.MigrationDebug 1
```

### Common Issues

```swift
// Issue: Objects not updating in UI
// Solution: Ensure @FetchRequest or manual refresh

// Issue: Crash on save
// Solution: Check constraints and required attributes

// Issue: Memory issues
// Solution: Use batch fetching and refresh objects

// Issue: CloudKit sync not working
// Solution: Check container configuration and logs
```

## Testing

### In-Memory Store

```swift
// ✅ For unit tests
class CoreDataStack {
    static func inMemory() -> CoreDataStack {
        let stack = CoreDataStack()
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        stack.persistentContainer.persistentStoreDescriptions = [description]
        return stack
    }
}
```

### Test Data

```swift
// ✅ Create test data
func createTestExpense(context: NSManagedObjectContext) -> Expense {
    let expense = Expense(context: context)
    expense.name = "Test Expense"
    expense.amount = 100.0
    expense.date = Date()
    return expense
}
```

## Common Patterns

### Singleton Core Data Stack

```swift
class CoreDataStack {
    static let sharedInstance = CoreDataStack()

    private init() { }

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Model")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
        return container
    }()

    var managedObjectContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func save() throws {
        let context = managedObjectContext
        if context.hasChanges {
            try context.save()
        }
    }
}
```

### ViewModel Integration

```swift
class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []

    private let context = CoreDataStack.sharedInstance.managedObjectContext

    func loadExpenses() {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Expense.date, ascending: false)
        ]

        do {
            expenses = try context.fetch(request)
        } catch {
            print("Failed to fetch: \(error)")
        }
    }

    func addExpense(name: String, amount: Double) {
        let expense = Expense(context: context)
        expense.name = name
        expense.amount = amount
        expense.date = Date()

        if context.hasChanges {
            try? context.save()
        }
        loadExpenses()
    }
}
```

## References

- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
