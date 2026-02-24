---
name: tdd-refactor-guard
description: Pre-refactor safety checklist. Verifies test coverage exists before AI modifies existing code. Use before asking AI to refactor anything.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# TDD Refactor Guard

A safety gate that runs before any AI-assisted refactoring. Ensures tests exist to catch regressions. If coverage is insufficient, generates characterization tests first.

## When This Skill Activates

Use this skill when the user:
- Says "refactor this" or "clean this up"
- Wants AI to "restructure" or "reorganize" code
- Asks to "extract", "inline", "rename", or "simplify" existing code
- Plans to migrate between patterns (e.g., MVC → MVVM, CoreData → SwiftData)
- Wants AI to "improve" or "modernize" existing code

## Why This Guard Exists

```
Without guard:               With guard:
"Claude, refactor this"      "Claude, refactor this"
  → AI rewrites code           → Guard checks for tests
  → Something breaks           → Tests missing → generate them
  → You don't know what        → Tests pass → proceed with refactor
  → Debugging nightmare         → Tests fail → exact regression found
```

## Process

### Step 1: Identify Scope

What code is being refactored?

```
Ask user: "Which files/classes are you planning to refactor?"
```

Or detect from context:
```
Glob: [files mentioned in conversation]
Read: each file to understand scope
```

Determine:
- [ ] Files involved
- [ ] Public API surface (methods, properties)
- [ ] Dependencies (what calls this code, what it calls)
- [ ] Side effects (network, disk, notifications, UI updates)

### Step 2: Check Existing Test Coverage

```
Grep: "class.*Tests.*XCTestCase|@Suite.*Tests|struct.*Tests" in test targets
Grep: "@Test|func test" that reference the classes being refactored
```

#### Coverage Assessment

| Level | Criteria | Action |
|-------|----------|--------|
| Good (> 80%) | Most public methods have tests for happy + error paths | Proceed with refactoring |
| Partial (40-80%) | Some methods tested, missing edge cases | Add characterization tests for uncovered methods |
| Minimal (< 40%) | Few or no tests | Generate full characterization test suite first |
| None (0%) | No test file exists | STOP — create characterization tests before any refactoring |

### Step 3: Evaluate Test Quality

Even if tests exist, check quality:

```swift
// ❌ Low-quality test — doesn't actually verify behavior
@Test("test items")
func testItems() {
    let vm = ViewModel()
    vm.loadItems()
    #expect(true)  // Always passes, tests nothing
}

// ❌ Tests implementation, not behavior
@Test("calls repository")
func testCallsRepo() {
    let vm = ViewModel()
    vm.loadItems()
    #expect(mockRepo.fetchCallCount == 1)  // Brittle
}

// ✅ Tests observable behavior
@Test("loads items into published array")
func testLoadsItems() async {
    let vm = ViewModel(repo: MockRepo(items: [.sample]))
    await vm.loadItems()
    #expect(vm.items.count == 1)
    #expect(vm.items.first?.title == "Sample")
}
```

**Quality checklist:**
- [ ] Tests verify **outputs/state**, not implementation details
- [ ] Both happy path and error paths covered
- [ ] Edge cases (empty, nil, boundary) tested
- [ ] Async behavior properly awaited
- [ ] No `#expect(true)` or always-passing assertions

### Step 4: Generate Missing Tests

If coverage is insufficient, use `characterization-test-generator/`:

```markdown
Before refactoring [ClassName], generate characterization tests:
1. Read the source file
2. Identify all public methods
3. Generate tests that capture CURRENT behavior
4. Run and verify all pass
```

### Step 5: Green Light / Red Light

#### Green Light — Proceed

```markdown
## Refactor Guard: ✅ PROCEED

**Files**: ItemManager.swift, ItemRepository.swift
**Test coverage**: Good (12 tests covering 8/9 public methods)
**Test quality**: Adequate — tests verify behavior, not implementation

Safe to refactor. Run tests after each change:
`xcodebuild test -scheme YourApp`
```

#### Yellow Light — Needs Work

```markdown
## Refactor Guard: ⚠️ NEEDS TESTS

**Files**: ItemManager.swift, ItemRepository.swift
**Test coverage**: Partial (5 tests covering 4/9 public methods)
**Missing coverage**:
- `ItemManager.sort()` — no test
- `ItemManager.filter(by:)` — no test
- `ItemRepository.sync()` — no test
- Error paths for `save()` and `delete()` — not tested

**Action**: Generate characterization tests for uncovered methods before refactoring.
Use `characterization-test-generator` skill.
```

#### Red Light — Stop

```markdown
## Refactor Guard: 🔴 STOP

**Files**: ItemManager.swift, ItemRepository.swift
**Test coverage**: None (0 tests found)

**Action**: Do NOT refactor until characterization tests exist.
Refactoring without tests is like surgery without monitoring —
you won't know if you killed the patient.

Run `characterization-test-generator` on:
1. ItemManager (7 public methods)
2. ItemRepository (5 public methods)

Then re-run this guard.
```

### Step 6: Post-Refactor Verification

After refactoring is complete:

```bash
# Run all tests
xcodebuild test -scheme YourApp

# Check specifically for regressions
xcodebuild test -scheme YourApp \
  -only-testing "YourAppTests/ItemManagerCharacterizationTests"
```

- [ ] All pre-existing tests still pass
- [ ] Characterization tests still pass
- [ ] No new warnings or errors
- [ ] Public API surface unchanged (unless intentionally changed)

## Refactoring Safeguards

### Safe Refactorings (Low Risk)

These typically don't change behavior:
- Rename variable/method/type
- Extract method/function
- Inline temporary variable
- Move method to another type (keeping same behavior)
- Extract protocol from class

### Risky Refactorings (Need Good Coverage)

These can change behavior:
- Change method signature
- Reorder operations
- Replace algorithm
- Merge/split classes
- Change data structure
- Introduce async/await to sync code
- Migration between frameworks (CoreData → SwiftData)

### Migration Refactorings (Need Comprehensive Coverage)

Full contract tests recommended:
- Architecture change (MVC → MVVM)
- Framework migration (UIKit → SwiftUI)
- Storage migration (UserDefaults → SwiftData)
- Concurrency model change (GCD → async/await)

## Output Format

```markdown
## Refactor Guard Report

**Scope**: [Files/classes to be refactored]
**Verdict**: ✅ PROCEED / ⚠️ NEEDS TESTS / 🔴 STOP

### Coverage Summary
| Class | Public Methods | Tests | Coverage | Verdict |
|-------|---------------|-------|----------|---------|
| ItemManager | 9 | 12 | 89% | ✅ |
| ItemRepository | 5 | 2 | 40% | ⚠️ |

### Missing Coverage
- [ ] `ItemRepository.sync()` — needs characterization test
- [ ] Error path for `ItemRepository.delete()` — untested

### Recommendations
1. [Action item]
2. [Action item]
```

## References

- `testing/characterization-test-generator/` — generates tests this guard may require
- `testing/tdd-feature/` — for building new code during refactor
- Martin Fowler, *Refactoring: Improving the Design of Existing Code*
