// ContractPinTests.swift — fitness function, Pattern 3
//
// Pins facts that must change DELIBERATELY, never by drift:
//  A. Count pins — registry/configuration sizes, with a comment trail so
//     every number carries its history. Updating a pin is a reviewed
//     decision with a written reason, not a chore.
//  B. Copy-contract pins — structural rules on user-facing content,
//     iterated over CaseIterable so new cases are covered automatically,
//     plus a few verbatim exemplars pinned with exact equality.
//
// Adapt the placeholder types to your registries and content surfaces.

import Testing
import Foundation

// Placeholder stand-ins so this template parses standalone — replace with
// your real types (an occasion/registry enum and a content-bearing enum).
enum PinnedRegistry: CaseIterable {
    case alpha, beta, gamma
    var isStreaming: Bool { self == .gamma }
    var displayLine: String { "example line" }
}

struct ContractPinTests {

    // MARK: - A. Count pins

    @Test func registrySizesMatchTheDocumentedContract() {
        // COMMENT TRAIL (mandatory): each number's history, so the next
        // person updating this pin writes the next line, e.g.:
        //   Phase 2 shipped 9 modes, 5 streaming.
        //   Phase 3 added the reunion pack — 15 modes, 9 streaming.
        #expect(PinnedRegistry.allCases.count == 3)
        #expect(PinnedRegistry.allCases.filter(\.isStreaming).count == 1)
    }

    // MARK: - B. Copy-contract pins

    @Test func everyCaseSatisfiesTheContentContract() {
        for entry in PinnedRegistry.allCases {
            // ADAPT: the structural rules that make the content shippable —
            // counts, length ceilings, non-empty invariants. Failure messages
            // name the case AND the offending value.
            #expect(!entry.displayLine.isEmpty, "\(entry) has an empty display line")
            #expect(
                entry.displayLine.count <= 60,
                "\(entry): \"\(entry.displayLine)\" is \(entry.displayLine.count) chars, over the 60-char limit"
            )
        }
    }

    /// Verbatim exemplars — exact equality, so a future content pass must
    /// change these deliberately, not by accident.
    @Test func exemplarContentPinnedVerbatim() {
        #expect(PinnedRegistry.alpha.displayLine == "example line")
    }
}
