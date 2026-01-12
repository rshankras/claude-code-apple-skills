---
name: coding-best-practices
description: Reviews Swift/iOS code for adherence to modern Swift idioms, Apple platform best practices, architecture patterns, and code quality standards. Use when user mentions best practices, code review, clean code, refactoring, or wants to improve code quality.
allowed-tools: [Read, Glob, Grep]
---

# Coding Best Practices Skill

Reviews Swift/iOS code for adherence to modern Swift idioms, Apple platform best practices, architecture patterns, and code quality standards.

## When This Skill Activates

Use this skill when the user:
- Asks for code review or code quality check
- Mentions "best practices", "clean code", or "refactoring"
- Wants to improve existing code
- Requests architecture or design pattern review
- Asks about Swift idioms or modern patterns
- Wants performance optimization suggestions

## Review Process

### 1. Identify Scope

- If user specifies files/classes, review those
- Otherwise, ask which areas to focus on or review recent changes
- Prioritize ViewModels, business logic, and data layer over simple views

### 2. Load Reference Patterns

Before starting the review, familiarize yourself with the reference patterns by reading the following files in `.claude/skills/coding-best-practices/`:

- **swift-patterns.md** - Optionals, type safety, collections, error handling, naming
- **swiftui-patterns.md** - State management, view composition, performance
- **architecture-patterns.md** - MVVM, code organization, memory management, security
- **coredata-patterns.md** - Core Data best practices, fetching, saving, relationships

### 3. Review Categories

Apply these review categories based on the code type:

**For All Code:**
- Swift language idioms (optionals, type safety, collections)
- Naming conventions
- Error handling
- Memory management

**For SwiftUI Code:**
- State management (@State, @StateObject, @ObservedObject)
- View composition and performance
- MVVM separation

**For ViewModels:**
- Business logic placement
- MVVM architecture adherence
- Testability (dependency injection)

**For Core Data Code:**
- Context management
- Save/fetch patterns
- Relationship handling
- CloudKit integration

### 4. Review Output Format

Provide review in this structure:

#### ✅ Strengths Found
- List well-implemented patterns
- Highlight good practices
- Acknowledge clean code sections

#### ⚠️ Issues Found

For each issue, use this format:

**Category: [Category Name]**

**[Priority]: [File.swift:line]** - [Issue description]
```swift
// Current:
[problematic code]

// Suggested:
[improved code]

// Reason: [explanation]
```

**Priority Levels:**
- **High**: Will cause bugs, crashes, or serious issues
- **Medium**: Inefficient, hard to maintain, or non-idiomatic
- **Low**: Minor improvements, nice-to-haves

#### 📊 Code Quality Score

**Overall: X/10**

- Swift Idioms: X/10
- Architecture: X/10
- Error Handling: X/10
- Naming: X/10
- Organization: X/10
- Performance: X/10

#### 📋 Recommendations

1. **High Priority**: [Critical issues]
2. **Medium Priority**: [Improvements]
3. **Low Priority**: [Nice-to-haves]

#### 🔧 Quick Wins

List 3-5 easy fixes that provide immediate value

## Review Checklist

Use this comprehensive checklist during review:

### Swift Language
- [ ] No force unwrapping unless intentional
- [ ] Proper optional handling (guard, if let, ??)
- [ ] Enums instead of string/int constants
- [ ] Functional collection operations (map, filter, etc.)
- [ ] Proper error handling (not silent try?)
- [ ] Clear, descriptive naming

### SwiftUI
- [ ] Correct property wrapper usage
- [ ] No ViewModels created in body
- [ ] Views broken into components
- [ ] No heavy computation in body
- [ ] Single source of truth

### Architecture
- [ ] MVVM separation maintained
- [ ] Business logic in ViewModels
- [ ] UI logic in Views only
- [ ] Proper code organization with MARK
- [ ] Private by default

### Core Data
- [ ] Using shared context
- [ ] hasChanges check before save
- [ ] Typed fetch requests
- [ ] Safe property access
- [ ] Proper error handling

### Memory Management
- [ ] [weak self] in escaping closures
- [ ] Weak delegates
- [ ] No retain cycles

### Testing & Security
- [ ] Testable code structure
- [ ] Dependency injection
- [ ] No hardcoded secrets
- [ ] Input validation
- [ ] Safe logging

## Example Review Output

```
Reviewing: ExpenseViewModel.swift

✅ Strengths Found
- Excellent use of @Published properties
- Clean separation between public and private methods
- Good error handling with custom error types
- Proper use of guard statements for early returns

⚠️ Issues Found

**Category: Optionals Handling**

**High Priority: ExpenseViewModel.swift:45** - Force unwrapping
// Current:
let payer = expense.payer!

// Suggested:
guard let payer = expense.payer else {
    print("Expense has no payer")
    return
}

// Reason: Force unwrapping will crash if payer is nil. Use guard for safe unwrapping.

**Category: Core Data**

**Medium Priority: ExpenseViewModel.swift:89** - Saving without checking hasChanges
// Current:
try? context.save()

// Suggested:
if context.hasChanges {
    do {
        try context.save()
    } catch {
        print("Failed to save: \(error.localizedDescription)")
    }
}

// Reason: Check hasChanges to avoid unnecessary saves. Handle errors properly.

**Category: Collections**

**Low Priority: ExpenseViewModel.swift:123** - Inefficient filtering
// Current:
let found = expenses.filter { $0.id == targetId }.first

// Suggested:
let found = expenses.first { $0.id == targetId }

// Reason: first(where:) stops at first match, filter processes entire array.

📊 Code Quality Score
**Overall: 7/10**

- Swift Idioms: 6/10 (force unwrapping, inefficient collection usage)
- Architecture: 9/10 (excellent MVVM separation)
- Error Handling: 7/10 (using try? too often)
- Naming: 9/10 (clear, descriptive names)
- Organization: 8/10 (good marks, could improve grouping)
- Performance: 7/10 (some inefficient patterns)

📋 Recommendations
1. **High Priority**: Remove all force unwrapping (5 instances found)
2. **Medium Priority**: Improve error handling (don't swallow errors with try?)
3. **Low Priority**: Use first(where:) instead of filter().first

🔧 Quick Wins
1. Replace `expense.payer!` with safe unwrapping (ExpenseViewModel.swift:45)
2. Add hasChanges check before context.save() (ExpenseViewModel.swift:89)
3. Use first(where:) for finding items (ExpenseViewModel.swift:123)
```

## Tips for Effective Reviews

### Be Constructive
- Provide clear code examples for every issue
- Explain WHY, not just WHAT
- Be educational, not judgmental

### Consider Context
- Some patterns are valid in certain scenarios
- Balance idealism with pragmatism
- Consider project constraints

### Prioritize Impact
- Focus on issues that affect correctness first
- Then performance and maintainability
- Style issues last

### Actionable Feedback
- Provide specific line numbers
- Show exact code to change
- Explain expected behavior

## References

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift.org Documentation](https://docs.swift.org/)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui)
- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)

## Notes

- Read the reference pattern files for detailed examples
- Focus on the most impactful improvements first
- Provide code examples for all suggested changes
- Reference exact file locations (filename.swift:lineNumber)
- Be thorough but constructive
