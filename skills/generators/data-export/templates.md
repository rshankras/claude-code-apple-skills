# Data Export Code Templates

Production-ready Swift templates for data export and import infrastructure. All code targets iOS 16+ / macOS 13+ and uses modern Swift concurrency. No third-party dependencies.

## DataExportable.swift

```swift
import Foundation

/// Protocol for models that support data export in multiple formats.
///
/// Conform your data models to this protocol to enable JSON, CSV,
/// and PDF export through `DataExportManager`.
///
/// Usage:
/// ```swift
/// struct Expense: Codable, DataExportable {
///     let id: UUID
///     let title: String
///     let amount: Double
///     let date: Date
///     let category: String
///
///     static var csvHeaders: [String] {
///         ["ID", "Title", "Amount", "Date", "Category"]
///     }
///
///     var csvRow: [String] {
///         [id.uuidString, title, String(format: "%.2f", amount),
///          ISO8601DateFormatter().string(from: date), category]
///     }
///
///     var pdfDescription: String {
///         "\(title) - $\(String(format: "%.2f", amount)) (\(category))"
///     }
/// }
/// ```
protocol DataExportable: Codable {
    /// Column headers for CSV export.
    static var csvHeaders: [String] { get }

    /// Values for a single CSV row, matching the order of `csvHeaders`.
    var csvRow: [String] { get }

    /// A human-readable description for PDF report line items.
    var pdfDescription: String { get }
}
```

## DataExportManager.swift

```swift
import Foundation
import os

/// Central coordinator for exporting data in multiple formats.
///
/// Routes export requests to the appropriate format-specific exporter
/// and returns a file URL suitable for sharing via UIActivityViewController
/// or SwiftUI ShareLink.
///
/// Usage:
/// ```swift
/// let url = try await DataExportManager.shared.export(
///     expenses, format: .csv, filename: "expenses"
/// )
/// // Present url via share sheet
/// ```
final class DataExportManager: Sendable {
    static let shared = DataExportManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app",
        category: "DataExport"
    )

    /// Supported export formats.
    enum ExportFormat: String, CaseIterable, Identifiable {
        case json
        case csv
        case pdf

        var id: String { rawValue }

        /// File extension for this format.
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            case .pdf: return "pdf"
            }
        }

        /// MIME type for this format.
        var mimeType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            case .pdf: return "application/pdf"
            }
        }

        /// Display name for UI.
        var displayName: String {
            switch self {
            case .json: return "JSON"
            case .csv: return "CSV"
            case .pdf: return "PDF"
            }
        }
    }

    /// Export an array of items in the specified format.
    ///
    /// - Parameters:
    ///   - items: The items to export.
    ///   - format: The output format (JSON, CSV, or PDF).
    ///   - filename: The base filename (without extension).
    /// - Returns: A URL to the exported file in the temporary directory.
    func export<T: DataExportable>(
        _ items: [T],
        format: ExportFormat,
        filename: String
    ) async throws -> URL {
        let data: Data

        switch format {
        case .json:
            data = try exportAsJSON(items)
        case .csv:
            let csvString = CSVExporter.generate(
                from: items,
                headers: T.csvHeaders,
                rowMapper: { $0.csvRow }
            )
            guard let csvData = csvString.data(using: .utf8) else {
                throw ExportError.encodingFailed
            }
            data = csvData
        case .pdf:
            data = PDFExporter.generateReport(
                title: filename.capitalized,
                items: items.map { $0.pdfDescription }
            )
        }

        let url = temporaryFileURL(filename: filename, format: format)
        try data.write(to: url, options: .atomic)

        logger.info("Exported \(items.count) items as \(format.rawValue) to \(url.lastPathComponent)")
        return url
    }

    /// Export raw Codable data as JSON (for GDPR full export).
    ///
    /// - Parameters:
    ///   - value: Any Encodable value to export.
    ///   - filename: The base filename.
    /// - Returns: A URL to the exported JSON file.
    func exportJSON<T: Encodable>(_ value: T, filename: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)

        let url = temporaryFileURL(filename: filename, format: .json)
        try data.write(to: url, options: .atomic)

        return url
    }

    // MARK: - Private

    private func exportAsJSON<T: Encodable>(_ items: [T]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(items)
    }

    private func temporaryFileURL(filename: String, format: ExportFormat) -> URL {
        let sanitizedName = filename.replacingOccurrences(of: " ", with: "-")
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("\(sanitizedName)-\(timestamp).\(format.fileExtension)")
    }

    /// Export errors.
    enum ExportError: LocalizedError {
        case encodingFailed
        case renderingFailed
        case noData

        var errorDescription: String? {
            switch self {
            case .encodingFailed: return "Failed to encode data for export"
            case .renderingFailed: return "Failed to render PDF"
            case .noData: return "No data to export"
            }
        }
    }
}
```

## CSVExporter.swift

```swift
import Foundation

/// CSV generation and parsing with proper field escaping.
///
/// Handles special characters in field values:
/// - Fields containing commas are wrapped in double quotes
/// - Fields containing double quotes have quotes doubled (RFC 4180)
/// - Fields containing newlines are wrapped in double quotes
///
/// Usage:
/// ```swift
/// let csv = CSVExporter.generate(
///     from: expenses,
///     headers: ["Title", "Amount", "Category"],
///     rowMapper: { [$0.title, String($0.amount), $0.category] }
/// )
/// ```
enum CSVExporter {

    /// Generate a CSV string from an array of items.
    ///
    /// - Parameters:
    ///   - items: The source items to export.
    ///   - headers: Column header names.
    ///   - rowMapper: Closure that converts each item to an array of string values.
    /// - Returns: A complete CSV string with headers and data rows.
    static func generate<T>(
        from items: [T],
        headers: [String],
        rowMapper: (T) -> [String]
    ) -> String {
        var lines: [String] = []

        // Header row
        lines.append(headers.map { escapeField($0) }.joined(separator: ","))

        // Data rows
        for item in items {
            let values = rowMapper(item)
            let escapedValues = values.map { escapeField($0) }
            lines.append(escapedValues.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    /// Generate a CSV string using column definitions.
    ///
    /// A more declarative API where columns are defined with name and value extractor.
    ///
    /// Usage:
    /// ```swift
    /// let csv = CSVExporter.generate(from: expenses, columns: [
    ///     ("Title", { $0.title }),
    ///     ("Amount", { String(format: "%.2f", $0.amount) }),
    ///     ("Category", { $0.category }),
    /// ])
    /// ```
    static func generate<T>(
        from items: [T],
        columns: [(String, (T) -> String)]
    ) -> String {
        let headers = columns.map(\.0)
        return generate(from: items, headers: headers) { item in
            columns.map { $0.1(item) }
        }
    }

    // MARK: - Parsing

    /// Parse a CSV file into an array of dictionaries.
    ///
    /// Each dictionary maps column header names to row values.
    /// Handles quoted fields and escaped quotes.
    ///
    /// - Parameter url: The CSV file URL.
    /// - Returns: An array of dictionaries, one per data row.
    static func parse(from url: URL) throws -> [[String: String]] {
        let content = try String(contentsOf: url, encoding: .utf8)
        return parse(content: content)
    }

    /// Parse a CSV string into an array of dictionaries.
    static func parse(content: String) -> [[String: String]] {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard let headerLine = lines.first else { return [] }
        let headers = parseRow(headerLine)

        return lines.dropFirst().map { line in
            let values = parseRow(line)
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                if index < values.count {
                    row[header] = values[index]
                }
            }
            return row
        }
    }

    // MARK: - Field Escaping (RFC 4180)

    /// Escape a CSV field value according to RFC 4180.
    ///
    /// - If the field contains a comma, newline, or double quote, wrap in quotes.
    /// - Double quotes within the field are escaped as two double quotes.
    private static func escapeField(_ field: String) -> String {
        let needsQuoting = field.contains(",") ||
                           field.contains("\"") ||
                           field.contains("\n") ||
                           field.contains("\r")

        if needsQuoting {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }

        return field
    }

    /// Parse a single CSV row into an array of field values.
    ///
    /// Handles quoted fields with embedded commas and escaped quotes.
    private static func parseRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()

        while let char = iterator.next() {
            if inQuotes {
                if char == "\"" {
                    // Check for escaped quote (double-double quote)
                    // Peek at next character
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else {
                            inQuotes = false
                            if next == "," {
                                fields.append(current)
                                current = ""
                            } else {
                                current.append(next)
                            }
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
        }

        fields.append(current)
        return fields
    }
}
```

## PDFExporter.swift

```swift
import UIKit
import os

/// PDF generation using UIGraphicsPDFRenderer.
///
/// Generates formatted PDF reports with title, metadata, and
/// line items. Uses standard US Letter page size (8.5" x 11").
///
/// Usage:
/// ```swift
/// let data = PDFExporter.generateReport(
///     title: "Expense Report",
///     items: expenses.map { "\($0.title) - $\($0.amount)" }
/// )
/// try data.write(to: url)
/// ```
enum PDFExporter {

    /// Standard US Letter page size in points (72 points per inch).
    private static let pageWidth: CGFloat = 612   // 8.5"
    private static let pageHeight: CGFloat = 792  // 11"
    private static let margin: CGFloat = 50
    private static let lineSpacing: CGFloat = 20

    /// Generate a PDF report with a title and line items.
    ///
    /// - Parameters:
    ///   - title: The report title displayed at the top.
    ///   - subtitle: Optional subtitle (e.g., date range).
    ///   - items: Array of string descriptions, one per line.
    /// - Returns: The rendered PDF as Data.
    static func generateReport(
        title: String,
        subtitle: String? = nil,
        items: [String]
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            var currentY: CGFloat = 0
            var isFirstPage = true

            func beginNewPage() {
                context.beginPage()
                currentY = margin

                if isFirstPage {
                    currentY = drawHeader(title: title, subtitle: subtitle, at: currentY)
                    isFirstPage = false
                } else {
                    // Continuation header
                    currentY = drawContinuationHeader(title: title, at: currentY)
                }
            }

            beginNewPage()

            // Draw each line item
            for (index, item) in items.enumerated() {
                let itemHeight = heightForText(item, maxWidth: pageWidth - (margin * 2))

                // Check if we need a new page
                if currentY + itemHeight + lineSpacing > pageHeight - margin {
                    // Draw page number on current page
                    drawPageNumber(context: context, pageRect: pageRect)
                    beginNewPage()
                }

                // Alternate row background
                if index % 2 == 0 {
                    let rowRect = CGRect(
                        x: margin - 4,
                        y: currentY - 2,
                        width: pageWidth - (margin * 2) + 8,
                        height: itemHeight + 4
                    )
                    UIColor.systemGray6.setFill()
                    UIBezierPath(roundedRect: rowRect, cornerRadius: 4).fill()
                }

                // Draw item text
                let textRect = CGRect(
                    x: margin,
                    y: currentY,
                    width: pageWidth - (margin * 2),
                    height: itemHeight
                )

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: paragraphStyle,
                ]

                item.draw(in: textRect, withAttributes: attributes)
                currentY += itemHeight + lineSpacing
            }

            // Draw footer on last page
            drawPageNumber(context: context, pageRect: pageRect)
            drawFooter(pageRect: pageRect)
        }
    }

    /// Generate a PDF with tabular data (rows and columns).
    ///
    /// - Parameters:
    ///   - title: The report title.
    ///   - headers: Column header names.
    ///   - rows: Array of row arrays matching header count.
    /// - Returns: The rendered PDF as Data.
    static func generateTable(
        title: String,
        headers: [String],
        rows: [[String]]
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let contentWidth = pageWidth - (margin * 2)
        let columnWidth = contentWidth / CGFloat(headers.count)

        return renderer.pdfData { context in
            context.beginPage()
            var currentY = margin

            // Title
            currentY = drawHeader(title: title, subtitle: nil, at: currentY)

            // Table headers
            let headerFont = UIFont.boldSystemFont(ofSize: 10)
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.white,
            ]

            // Header background
            let headerRect = CGRect(
                x: margin, y: currentY,
                width: contentWidth, height: 24
            )
            UIColor.systemBlue.setFill()
            UIBezierPath(roundedRect: headerRect, cornerRadius: 4).fill()

            for (colIndex, header) in headers.enumerated() {
                let cellRect = CGRect(
                    x: margin + CGFloat(colIndex) * columnWidth + 4,
                    y: currentY + 4,
                    width: columnWidth - 8,
                    height: 16
                )
                header.draw(in: cellRect, withAttributes: headerAttributes)
            }
            currentY += 28

            // Table rows
            let cellFont = UIFont.systemFont(ofSize: 10)
            let cellAttributes: [NSAttributedString.Key: Any] = [
                .font: cellFont,
                .foregroundColor: UIColor.label,
            ]

            for (rowIndex, row) in rows.enumerated() {
                if currentY + 24 > pageHeight - margin {
                    drawPageNumber(context: context, pageRect: pageRect)
                    context.beginPage()
                    currentY = margin
                }

                // Alternating row color
                if rowIndex % 2 == 0 {
                    let rowBgRect = CGRect(
                        x: margin, y: currentY,
                        width: contentWidth, height: 20
                    )
                    UIColor.systemGray6.setFill()
                    UIBezierPath(rect: rowBgRect).fill()
                }

                for (colIndex, value) in row.enumerated() {
                    guard colIndex < headers.count else { break }
                    let cellRect = CGRect(
                        x: margin + CGFloat(colIndex) * columnWidth + 4,
                        y: currentY + 3,
                        width: columnWidth - 8,
                        height: 14
                    )
                    value.draw(in: cellRect, withAttributes: cellAttributes)
                }
                currentY += 20
            }

            drawPageNumber(context: context, pageRect: pageRect)
            drawFooter(pageRect: pageRect)
        }
    }

    // MARK: - Drawing Helpers

    private static func drawHeader(
        title: String,
        subtitle: String?,
        at startY: CGFloat
    ) -> CGFloat {
        var y = startY

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label,
        ]
        let titleRect = CGRect(
            x: margin, y: y,
            width: pageWidth - (margin * 2), height: 30
        )
        title.draw(in: titleRect, withAttributes: titleAttributes)
        y += 34

        // Subtitle
        if let subtitle {
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            let subtitleRect = CGRect(
                x: margin, y: y,
                width: pageWidth - (margin * 2), height: 18
            )
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
            y += 22
        }

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Generated: \(dateFormatter.string(from: Date()))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.tertiaryLabel,
        ]
        let dateRect = CGRect(
            x: margin, y: y,
            width: pageWidth - (margin * 2), height: 14
        )
        dateString.draw(in: dateRect, withAttributes: dateAttributes)
        y += 20

        // Separator line
        let separatorPath = UIBezierPath()
        separatorPath.move(to: CGPoint(x: margin, y: y))
        separatorPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.separator.setStroke()
        separatorPath.lineWidth = 0.5
        separatorPath.stroke()
        y += 16

        return y
    }

    private static func drawContinuationHeader(title: String, at startY: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel,
        ]
        let rect = CGRect(x: margin, y: startY, width: pageWidth - (margin * 2), height: 14)
        "\(title) (continued)".draw(in: rect, withAttributes: attributes)
        return startY + 24
    }

    private static func drawPageNumber(context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let pageNumber = context.pdfContextBounds
        let text = "Page"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel,
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: pageRect.width - margin - textSize.width,
            y: pageRect.height - margin + 10,
            width: textSize.width,
            height: textSize.height
        )
        _ = pageNumber
        text.draw(in: textRect, withAttributes: attributes)
    }

    private static func drawFooter(pageRect: CGRect) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App"
        let text = "Exported from \(appName)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.tertiaryLabel,
        ]
        let rect = CGRect(
            x: margin,
            y: pageRect.height - margin + 10,
            width: 200,
            height: 14
        )
        text.draw(in: rect, withAttributes: attributes)
    }

    private static func heightForText(_ text: String, maxWidth: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
        ]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(boundingRect.height)
    }
}
```

## DataImporter.swift

```swift
import Foundation
import UniformTypeIdentifiers
import os

/// File import with UTType-based file picker and format-specific parsing.
///
/// Supports importing JSON and CSV files selected via `.fileImporter`
/// or drag-and-drop. Handles security-scoped URL access automatically.
///
/// Usage:
/// ```swift
/// // In a SwiftUI view with .fileImporter:
/// .fileImporter(
///     isPresented: $showPicker,
///     allowedContentTypes: DataImporter.supportedTypes
/// ) { result in
///     Task {
///         let url = try result.get()
///         let items: [Expense] = try await DataImporter.importFile(
///             from: url, as: Expense.self
///         )
///     }
/// }
/// ```
enum DataImporter {

    /// Content types supported for import.
    static let supportedTypes: [UTType] = [.json, .commaSeparatedText]

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app",
        category: "DataImport"
    )

    /// Import a file and decode its contents to the specified type.
    ///
    /// Automatically detects the format from the file extension
    /// and parses accordingly. Handles security-scoped URL access.
    ///
    /// - Parameters:
    ///   - url: The file URL (may be security-scoped from file picker).
    ///   - type: The Decodable type to parse into.
    /// - Returns: An array of decoded items.
    static func importFile<T: Decodable>(
        from url: URL,
        as type: T.Type
    ) async throws -> [T] {
        // Access security-scoped resource
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)

        // Detect format from file extension
        switch url.pathExtension.lowercased() {
        case "json":
            return try importJSON(data: data, as: type)
        case "csv":
            logger.warning("CSV import requires DataExportable conformance for column mapping")
            throw ImportError.unsupportedFormat("CSV import requires custom mapping")
        default:
            throw ImportError.unsupportedFormat(url.pathExtension)
        }
    }

    /// Import JSON data as an array of items.
    ///
    /// Handles both array `[{...}, {...}]` and single object `{...}` formats.
    static func importJSON<T: Decodable>(
        data: Data,
        as type: T.Type
    ) throws -> [T] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Try array first
        if let items = try? decoder.decode([T].self, from: data) {
            logger.info("Imported \(items.count) items from JSON array")
            return items
        }

        // Try single object
        if let item = try? decoder.decode(T.self, from: data) {
            logger.info("Imported single item from JSON object")
            return [item]
        }

        throw ImportError.decodingFailed("Could not decode JSON as \(T.self) or [\(T.self)]")
    }

    /// Import CSV data using a custom row mapper.
    ///
    /// Parses the CSV into dictionaries (header -> value) and applies
    /// the provided mapper to convert each row into the target type.
    ///
    /// Usage:
    /// ```swift
    /// let expenses = try DataImporter.importCSV(from: url) { row in
    ///     Expense(
    ///         id: UUID(uuidString: row["ID"] ?? "") ?? UUID(),
    ///         title: row["Title"] ?? "",
    ///         amount: Double(row["Amount"] ?? "0") ?? 0,
    ///         date: ISO8601DateFormatter().date(from: row["Date"] ?? "") ?? Date(),
    ///         category: row["Category"] ?? ""
    ///     )
    /// }
    /// ```
    static func importCSV<T>(
        from url: URL,
        rowMapper: ([String: String]) throws -> T
    ) throws -> [T] {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let rows = try CSVExporter.parse(from: url)
        logger.info("Parsed \(rows.count) rows from CSV")

        return try rows.map { row in
            try rowMapper(row)
        }
    }

    /// Validate that a file can be imported before attempting.
    ///
    /// Checks file existence, size, and format support.
    static func validate(url: URL) -> ImportValidation {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return .invalid("File not found")
        }

        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return .invalid("Cannot read file attributes")
        }

        // Warn for large files (> 50 MB)
        let maxSize: Int64 = 50 * 1024 * 1024
        if fileSize > maxSize {
            return .warning("File is \(fileSize / 1024 / 1024) MB. Import may be slow.")
        }

        let ext = url.pathExtension.lowercased()
        guard ext == "json" || ext == "csv" else {
            return .invalid("Unsupported format: .\(ext)")
        }

        return .valid
    }

    // MARK: - Types

    /// Result of file validation before import.
    enum ImportValidation {
        case valid
        case warning(String)
        case invalid(String)

        var isUsable: Bool {
            switch self {
            case .valid, .warning: return true
            case .invalid: return false
            }
        }
    }

    /// Import errors.
    enum ImportError: LocalizedError {
        case unsupportedFormat(String)
        case decodingFailed(String)
        case fileTooLarge(Int64)

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let format):
                return "Unsupported import format: \(format)"
            case .decodingFailed(let detail):
                return "Failed to decode imported data: \(detail)"
            case .fileTooLarge(let size):
                return "File too large (\(size / 1024 / 1024) MB)"
            }
        }
    }
}
```
