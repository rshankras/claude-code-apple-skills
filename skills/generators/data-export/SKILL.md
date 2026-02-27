---
name: data-export
description: Generates data export/import infrastructure for JSON, CSV, PDF formats with GDPR data portability, share sheet integration, and file import. Use when user wants data export functionality, CSV/JSON/PDF export, GDPR compliance data portability, import from files, or share sheet for data.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Data Export Generator

Generate production data export and import infrastructure -- JSON export via Codable, CSV generation with proper escaping, PDF report rendering with UIGraphicsPDFRenderer, GDPR-compliant full data export, file import with UTType-based picker, and share sheet integration. No third-party dependencies.

## When This Skill Activates

Use this skill when the user:
- Asks to "add data export" or "export user data"
- Wants "CSV export" or "JSON export" or "PDF export"
- Mentions "GDPR data portability" or "right to data portability"
- Asks about "exporting all user data" for compliance
- Wants to "import data" from files or competitor apps
- Mentions "share sheet" for exporting data
- Asks about "data backup" or "data download"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Identify data model layer (SwiftData, Core Data, custom structs)
- [ ] Identify source file locations

### 2. Existing Export Detection
Search for existing export code:
```
Glob: **/*Export*.swift, **/*Import*.swift, **/*CSV*.swift, **/*PDF*.swift
Grep: "UIGraphicsPDFRenderer" or "CSVExport" or "UIActivityViewController" or "ShareLink" or "fileExporter"
```

If existing export code found:
- Ask if user wants to replace or add additional formats
- Identify which formats are already supported

### 3. Data Model Detection
Search for data models that need exporting:
```
Grep: "@Model" or "NSManagedObject" or "struct.*Codable" or "class.*Codable"
```

Identify the models to build export conformances for.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Export formats needed?**
   - JSON (structured, machine-readable, best for GDPR)
   - CSV (tabular data, spreadsheet-compatible)
   - PDF (formatted reports with headers, tables, branding)
   - Multiple (select which combination)

2. **What data needs exporting?**
   - All user data -- GDPR compliance (every piece of stored user data)
   - Specific data types (user selects which models to export)
   - Reports/summaries (aggregated data, not raw records)

3. **Do you need import capability?**
   - No -- export only
   - Yes -- from files (JSON, CSV via file picker)
   - Yes -- from competitor apps (custom format parsing)

4. **How should users trigger export?**
   - Share sheet (system share UI with multiple destinations)
   - Settings screen (dedicated export section)
   - Export button (inline in content views)
   - Automatic backup (periodic export to iCloud/local)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `DataExportManager.swift` -- Central export coordinator with format routing
2. `DataExportable.swift` -- Protocol for models that support export

### Step 3: Create Format-Specific Files
Based on configuration:
3. `CSVExporter.swift` -- If CSV format selected
4. `PDFExporter.swift` -- If PDF format selected

### Step 4: Create Import Files
If import capability selected:
5. `DataImporter.swift` -- File picker and format parser

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/DataExport/`
- If `App/` exists -> `App/DataExport/`
- Otherwise -> `DataExport/`

## Output Format

After generation, provide:

### Files Created
```
DataExport/
├── DataExportable.swift   # Protocol for exportable models
├── DataExportManager.swift # Central export coordinator
├── CSVExporter.swift       # CSV generation (optional)
├── PDFExporter.swift       # PDF rendering (optional)
└── DataImporter.swift      # File import (optional)
```

### Integration with Data Models

**Make a model exportable:**
```swift
struct Expense: Codable, DataExportable {
    let id: UUID
    let title: String
    let amount: Double
    let date: Date
    let category: String

    // DataExportable conformance
    static var csvHeaders: [String] {
        ["ID", "Title", "Amount", "Date", "Category"]
    }

    var csvRow: [String] {
        [id.uuidString, title, String(format: "%.2f", amount),
         ISO8601DateFormatter().string(from: date), category]
    }

    var pdfDescription: String {
        "\(title) - $\(String(format: "%.2f", amount)) (\(category))"
    }
}
```

**Export from a view:**
```swift
struct ExpenseListView: View {
    let expenses: [Expense]
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        List(expenses) { expense in
            ExpenseRow(expense: expense)
        }
        .toolbar {
            Menu {
                Button("Export as JSON") {
                    Task { await exportAs(.json) }
                }
                Button("Export as CSV") {
                    Task { await exportAs(.csv) }
                }
                Button("Export as PDF") {
                    Task { await exportAs(.pdf) }
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
    }

    private func exportAs(_ format: DataExportManager.ExportFormat) async {
        do {
            exportURL = try await DataExportManager.shared.export(
                expenses, format: format, filename: "expenses"
            )
            showShareSheet = true
        } catch {
            // Handle error
        }
    }
}
```

**SwiftUI ShareLink (iOS 16+):**
```swift
if let url = exportURL {
    ShareLink(item: url) {
        Label("Share Export", systemImage: "square.and.arrow.up")
    }
}
```

**Import from file picker:**
```swift
struct ImportView: View {
    @State private var showFilePicker = false
    @State private var importedItems: [Expense] = []

    var body: some View {
        Button("Import Data") { showFilePicker = true }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: DataImporter.supportedTypes
            ) { result in
                Task {
                    let url = try result.get()
                    importedItems = try await DataImporter.importFile(
                        from: url, as: Expense.self
                    )
                }
            }
    }
}
```

### GDPR Data Portability

For full GDPR compliance, export ALL user data:
```swift
func exportAllUserData() async throws -> URL {
    let allData = GDPRExportData(
        profile: try await fetchUserProfile(),
        expenses: try await fetchAllExpenses(),
        settings: try await fetchUserSettings(),
        exportDate: Date(),
        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(allData)

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("user-data-export.json")
    try data.write(to: url)
    return url
}
```

### Testing

```swift
@Test
func jsonExportRoundTrip() async throws {
    let expenses = [
        Expense(id: UUID(), title: "Coffee", amount: 4.50,
                date: Date(), category: "Food")
    ]

    let url = try await DataExportManager.shared.export(
        expenses, format: .json, filename: "test"
    )
    let data = try Data(contentsOf: url)
    let decoded = try JSONDecoder().decode([Expense].self, from: data)

    #expect(decoded.count == 1)
    #expect(decoded.first?.title == "Coffee")
}

@Test
func csvExportFormatsCorrectly() {
    let expenses = [
        Expense(id: UUID(), title: "Coffee, Large", amount: 4.50,
                date: Date(), category: "Food")
    ]

    let csv = CSVExporter.generate(
        from: expenses,
        headers: Expense.csvHeaders,
        rowMapper: { $0.csvRow }
    )

    #expect(csv.contains("\"Coffee, Large\""))  // Commas escaped with quotes
    #expect(csv.hasPrefix("ID,Title,Amount,Date,Category"))
}

@Test
func importParsesCSV() async throws {
    let csvContent = "ID,Title,Amount\n1,Coffee,4.50\n2,Lunch,12.00"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.csv")
    try csvContent.write(to: url, atomically: true, encoding: .utf8)

    let rows = try CSVExporter.parse(from: url)
    #expect(rows.count == 2)
    #expect(rows.first?["Title"] == "Coffee")
}
```

## Common Patterns

### Export to Temporary File for Sharing
Always export to a temporary directory, then present via share sheet:
```swift
let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("export.\(format.fileExtension)")
try data.write(to: url)
// Present via UIActivityViewController or ShareLink
```

### GDPR Export Should Include Everything
For GDPR Article 20 compliance, export must include:
- All personal data the user provided
- All data generated about the user
- In a structured, machine-readable format (JSON recommended)
- With clear field descriptions

### CSV Must Handle Special Characters
Commas, quotes, and newlines in field values must be properly escaped:
- Fields containing commas: wrap in double quotes
- Fields containing quotes: escape with double-double quotes
- Fields containing newlines: wrap in double quotes

## Gotchas

### Temporary Files Cleanup
Files in `FileManager.default.temporaryDirectory` are cleaned up by the system periodically, but not immediately. For large exports, delete the file after sharing completes to free disk space.

### PDF Rendering on Background Thread
`UIGraphicsPDFRenderer` must be used on the main thread if it references UIKit views. For data-only PDF generation (text, lines, rectangles), it is safe to render on a background thread.

### Large Dataset Memory
For exporting thousands of records, stream the output instead of building the entire string/data in memory. Write CSV line-by-line to a file handle. For JSON, use JSONSerialization with streams.

### ShareLink vs UIActivityViewController
SwiftUI `ShareLink` (iOS 16+) is simpler but less configurable. `UIActivityViewController` gives full control over excluded activities, completion handlers, and custom activities.

### File Import Security Scoped URLs
When using `.fileImporter`, the returned URL is security-scoped. You must call `url.startAccessingSecurityScopedResource()` before reading and `url.stopAccessingSecurityScopedResource()` after.

## References

- **templates.md** -- All production Swift templates for data export/import
- [UIGraphicsPDFRenderer](https://developer.apple.com/documentation/uikit/uigraphicspdfrenderer)
- [UIActivityViewController](https://developer.apple.com/documentation/uikit/uiactivityviewcontroller)
- [UniformTypeIdentifiers](https://developer.apple.com/documentation/uniformtypeidentifiers)
- [GDPR Article 20 - Right to Data Portability](https://gdpr-info.eu/art-20-gdpr/)
- Related: `generators/settings-screen` -- Settings screen with export button
- Related: `generators/account-deletion` -- Account deletion includes data export option
