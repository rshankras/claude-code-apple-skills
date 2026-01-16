---
name: logging-setup
description: Generates structured logging infrastructure using os.log/Logger to replace print() statements. Use when user wants to add proper logging, replace print statements, or set up app logging.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Logging Setup Generator

Replace print() statements with Apple's structured logging system (os.log/Logger) for better debugging, privacy controls, and Console.app integration.

## When This Skill Activates

Use this skill when the user:
- Asks to "add logging" or "set up logging"
- Wants to "replace print statements"
- Mentions "os.log", "Logger", or "structured logging"
- Asks about "debug logging" or "production logging"
- Wants to audit print() usage in their codebase

## Why Logger Over print()

| print() | Logger |
|---------|--------|
| Always executes | Debug logs compiled out in Release |
| No filtering | Filter by subsystem/category in Console.app |
| No privacy | .private, .public, .sensitive annotations |
| String interpolation always runs | Deferred evaluation (performance) |
| Not in Console.app | Full system integration |

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (Logger requires iOS 14+ / macOS 11+)
- [ ] Search for existing Logger/os.log usage
- [ ] Identify source file locations (Sources/, App/, etc.)

### 2. Conflict Detection
Search for existing logging:
```
Glob: **/*Logger*.swift
Grep: "import OSLog" or "os_log"
```

If found, ask user:
- Extend existing logging?
- Replace with new implementation?
- Create separate logger?

## Modes of Operation

### Mode 1: Audit
Find all print() statements and report:
```
Grep: print\s*\(
```

Report format:
- File:line - print statement
- Severity: Info/Warning/Error (based on context)
- Suggested Logger level

### Mode 2: Generate
Create logging infrastructure from scratch.

### Mode 3: Migrate
Convert existing print() to Logger with suggestions.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Categories needed?**
   - Network, Auth, UI, Data (defaults)
   - Custom categories?

2. **Include migration helpers?**
   - Extension on String for quick migration
   - Temporary print-to-log bridge

## Generation Process

### Step 1: Create AppLogger.swift

Read template from `templates/AppLogger.swift` and customize:
- Set subsystem from Bundle.main.bundleIdentifier
- Add user-specified categories
- Include usage examples in comments

### Step 2: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Logging/AppLogger.swift`
- If `App/` exists → `App/Logging/AppLogger.swift`
- Otherwise → `Logging/AppLogger.swift`

### Step 3: Provide Migration Guidance

Show examples of converting common print patterns:
```swift
// Before
print("User logged in: \(email)")

// After
AppLogger.auth.info("User logged in: \(email, privacy: .private)")
```

## Output Format

After generation, provide:

### Files Created
- `[Path]/Logging/AppLogger.swift`

### Integration Steps
1. Import in files: `import OSLog` (not needed if using AppLogger)
2. Replace print() calls with AppLogger.[category].[level]()
3. Add privacy annotations for sensitive data

### Privacy Annotations Guide
- `.public` - Safe to log (IDs, counts, non-sensitive)
- `.private` - Redacted in release (emails, names)
- `.sensitive` - Always redacted (passwords, tokens)

### Console.app Usage
1. Open Console.app
2. Filter by subsystem: `com.yourapp`
3. Filter by category: `Network`, `Auth`, etc.

### Testing Instructions
1. Add a test log: `AppLogger.general.debug("Test log")`
2. Run app, check Xcode console
3. Open Console.app, filter by your app's subsystem

## References

- **logger-patterns.md** - Best practices and privacy levels
- **migration-guide.md** - Converting print() to Logger
- **templates/AppLogger.swift** - Template file
