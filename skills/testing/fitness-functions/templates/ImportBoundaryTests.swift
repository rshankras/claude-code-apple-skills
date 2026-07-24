// ImportBoundaryTests.swift — fitness function, Pattern 1
//
// Enforces: "only the files in `expectedImporters` may import <Framework>."
// Adapt the three ALL-CAPS placeholders, drop into the existing unit-test
// target, then run the deliberate-break drill (add the import to one outside
// file → this suite MUST fail → revert).
//
// Rules baked in:
//  - Source root derived from #filePath (never a hardcoded checkout path).
//  - Exact trimmed-line match, so comments *about* the rule don't count.
//  - Full-set comparison — the failure names the drifted file(s).
//  - Companion API-surface scan: an import fence alone can't catch a file
//    reaching the underlying API directly (every file already imports
//    Foundation, which is enough to construct a URLSession).

import Testing
import Foundation

struct ImportBoundaryTests {

    // ADAPT: framework being fenced, e.g. "MusicKit", "CloudKit".
    private static let fencedImport = "import FENCED_FRAMEWORK"

    // ADAPT: the fence, not a headcount. Each entry carries the reason it is
    // INSIDE the boundary; widening this set is a documented decision made
    // when this test fails on a file that genuinely belongs inside.
    private static let expectedImporters: Set<String> = [
        "EngineFile.swift",        // the boundary owner
        "EngineCompanion.swift",   // feeds the engine; inside the fence by design
    ]

    /// The shipped production source tree — sibling of this test target's
    /// directory. ADAPT the final path component to the app source folder.
    private var productionSourceRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // this file
            .deletingLastPathComponent() // the test target directory
            .appendingPathComponent("APP_SOURCE_DIRECTORY")
    }

    private func swiftFiles(in root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            // ADAPT: exclude non-shipping dirs (DEBUG-only spikes, generated
            // code) DELIBERATELY, with the reason: the guarantee is about
            // what ships.
            .filter { !$0.path.contains("/Spikes/") }
    }

    /// A line that IS the import (not a comment mentioning it).
    private func hasFencedImport(_ contents: String) -> Bool {
        contents
            .split(separator: "\n", omittingEmptySubsequences: false)
            .contains { $0.trimmingCharacters(in: .whitespaces) == Self.fencedImport }
    }

    @Test func onlyAllowlistedFilesImportTheFencedFramework() throws {
        let files = swiftFiles(in: productionSourceRoot)
        #expect(!files.isEmpty, "expected the source tree at \(productionSourceRoot.path)")

        var actualImporters: Set<String> = []
        for file in files {
            guard let contents = try? String(contentsOf: file, encoding: .utf8) else {
                Issue.record("could not read \(file.path)")
                continue
            }
            if hasFencedImport(contents) {
                actualImporters.insert(file.lastPathComponent)
            }
        }

        #expect(
            actualImporters == Self.expectedImporters,
            "importers drifted from the boundary contract — got \(actualImporters.sorted()), expected \(Self.expectedImporters.sorted())"
        )
    }

    /// Companion scan: the raw API surface, outside the same boundary.
    /// ADAPT the needles to the bypass routes that matter for your fence
    /// (for a network fence: URLSession construction and the shared session).
    @Test func noFileOutsideTheBoundaryUsesTheRawAPIDirectly() throws {
        let files = swiftFiles(in: productionSourceRoot)
        #expect(!files.isEmpty, "expected the source tree at \(productionSourceRoot.path)")

        let bypassNeedles = ["URLSession(", "URLSession.shared"]

        for file in files where !Self.expectedImporters.contains(file.lastPathComponent) {
            guard let contents = try? String(contentsOf: file, encoding: .utf8) else {
                Issue.record("could not read \(file.path)")
                continue
            }
            for needle in bypassNeedles {
                #expect(
                    !contents.contains(needle),
                    "\(file.lastPathComponent) uses \(needle) outside the boundary — the fence covers the API, not just the import"
                )
            }
        }
    }
}
