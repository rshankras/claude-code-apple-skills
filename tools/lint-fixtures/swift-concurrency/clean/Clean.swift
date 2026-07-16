final class Cache: @unchecked Sendable { // all mutation serialized on internal queue
    private var storage: [String: Int] = [:]
}

struct Snapshot: Sendable {
    let values: [Int]
}
