// NetworkSentinelTests.swift — fitness function, Pattern 2
//
// Enforces: "this code path never ATTEMPTS a network request" — stronger
// than "happens to succeed offline." The sentinel intercepts every request
// made through URLSession's default-configuration loading system, counts
// it, and fails it loudly (it never reaches the network) — so a regression
// fails in CI instead of silently succeeding against a live server.
//
// Adapt the marked section to drive YOUR real production path (real
// service, real composition; only storage in-memory), then assert the
// counter stayed at zero.

import Testing
import Foundation

struct NetworkSentinelTests {

    @Test func guaranteedOfflinePathIssuesNoNetworkRequests() async throws {
        NetworkSentinelProtocol.reset()
        URLProtocol.registerClass(NetworkSentinelProtocol.self)
        defer { URLProtocol.unregisterClass(NetworkSentinelProtocol.self) }

        // ADAPT: drive the real production path end-to-end, e.g.
        //   let service = DeckService(modelContainer: inMemoryContainer())
        //   let result = await service.build(request, capability: .templateFallback)
        //   ...assert the path completed successfully first...
        try await runTheOfflineGuaranteedPath()

        #expect(
            NetworkSentinelProtocol.interceptedRequestCount == 0,
            "the offline-guaranteed path attempted \(NetworkSentinelProtocol.interceptedRequestCount) network request(s)"
        )
    }

    // ADAPT: replace with the real path under guarantee.
    private func runTheOfflineGuaranteedPath() async throws {}
}

/// Registered for the duration of one test — intercepts, counts, and fails
/// every request it sees. The contract asserted above is ZERO ATTEMPTS,
/// not zero successes.
final class NetworkSentinelProtocol: URLProtocol, @unchecked Sendable {
    // Test-only counter; one test method drives one sequential path.
    nonisolated(unsafe) private static var count = 0

    static var interceptedRequestCount: Int { count }
    static func reset() { count = 0 }

    override class func canInit(with request: URLRequest) -> Bool {
        count += 1
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let error = NSError(
            domain: "FitnessFunctions.NetworkSentinel",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "network access attempted on an offline-guaranteed path"]
        )
        client?.urlProtocol(self, didFailWithError: error)
    }

    override func stopLoading() {}
}
