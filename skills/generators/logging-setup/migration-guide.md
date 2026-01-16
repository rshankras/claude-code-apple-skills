# print() to Logger Migration Guide

## Quick Migration Reference

| print() Pattern | Logger Equivalent |
|-----------------|-------------------|
| `print("Message")` | `AppLogger.general.info("Message")` |
| `print("Error: \(error)")` | `AppLogger.general.error("Error: \(error)")` |
| `print("Debug: \(value)")` | `AppLogger.general.debug("Debug: \(value, privacy: .private)")` |
| `print("User: \(email)")` | `AppLogger.auth.info("User: \(email, privacy: .private)")` |

## Migration by Context

### Debug Output
```swift
// Before
print("DEBUG: \(someValue)")
print(">>> \(debugInfo)")

// After
AppLogger.general.debug("\(someValue, privacy: .private)")
```

### Error Logging
```swift
// Before
print("Error: \(error)")
print("Failed to load: \(error.localizedDescription)")

// After
AppLogger.general.error("Failed to load: \(error.localizedDescription)")
```

### Network Debugging
```swift
// Before
print("Request: \(url)")
print("Response: \(statusCode)")
print("Body: \(responseBody)")

// After
AppLogger.network.debug("Request: \(url, privacy: .public)")
AppLogger.network.info("Response: \(statusCode, privacy: .public)")
AppLogger.network.debug("Body: \(responseBody, privacy: .private)")
```

### User Data
```swift
// Before
print("User logged in: \(email)")
print("User ID: \(userId)")

// After
AppLogger.auth.info("User logged in: \(email, privacy: .private)")
AppLogger.auth.info("User ID: \(userId, privacy: .private(mask: .hash))")
```

### State Changes
```swift
// Before
print("State changed to: \(newState)")

// After
AppLogger.ui.debug("State changed to: \(String(describing: newState), privacy: .public)")
```

## Bulk Migration Strategy

### Step 1: Audit Current print() Usage

Run this search to find all print statements:
```
Grep pattern: print\s*\(
```

### Step 2: Categorize by Purpose

Group print statements by their purpose:
- **Debug/Development**: → `.debug` level
- **Information**: → `.info` level
- **Warnings**: → `.warning` level
- **Errors**: → `.error` level

### Step 3: Assign Categories

Map to appropriate logger categories:
- Network/API calls → `AppLogger.network`
- Authentication → `AppLogger.auth`
- Data operations → `AppLogger.data`
- UI/Navigation → `AppLogger.ui`
- General/Other → `AppLogger.general`

### Step 4: Add Privacy Annotations

Review each log for sensitive data:
- User identifiable info → `.private`
- Passwords/tokens → `.sensitive`
- IDs, counts, status codes → `.public`

## Common Migration Patterns

### Function Entry/Exit
```swift
// Before
func processOrder(_ order: Order) {
    print("Processing order: \(order.id)")
    // ... work ...
    print("Order processed")
}

// After
func processOrder(_ order: Order) {
    AppLogger.data.debug("Processing order: \(order.id, privacy: .private(mask: .hash))")
    // ... work ...
    AppLogger.data.info("Order processed: \(order.id, privacy: .private(mask: .hash))")
}
```

### Conditional Logging
```swift
// Before
#if DEBUG
print("Debug info: \(value)")
#endif

// After (no #if needed - debug logs are compiled out in release)
AppLogger.general.debug("Debug info: \(value, privacy: .private)")
```

### Error Handling
```swift
// Before
do {
    try something()
} catch {
    print("Error: \(error)")
}

// After
do {
    try something()
} catch {
    AppLogger.general.error("Operation failed: \(error.localizedDescription)")
}
```

### Performance Logging
```swift
// Before
let start = Date()
// ... work ...
print("Took: \(Date().timeIntervalSince(start))s")

// After
let start = CFAbsoluteTimeGetCurrent()
// ... work ...
let duration = CFAbsoluteTimeGetCurrent() - start
AppLogger.performance.info("Operation took \(duration, format: .fixed(precision: 3))s")
```

## Temporary Migration Helper

If you want to migrate gradually, you can create a temporary bridge:

```swift
// TEMPORARY: Remove after full migration
func debugPrint(_ message: String, file: String = #file, line: Int = #line) {
    #if DEBUG
    let filename = (file as NSString).lastPathComponent
    AppLogger.general.debug("[\(filename):\(line)] \(message)")
    #endif
}

// Usage during migration
debugPrint("Old print statement") // Easy to find and replace later
```

## Verification Checklist

After migration:
- [ ] No print() statements remain (or only intentional ones)
- [ ] All user data has privacy annotations
- [ ] Appropriate log levels used
- [ ] Categories match the code area
- [ ] App builds without warnings
- [ ] Logs appear in Console.app with correct subsystem
