// Compact.swift — clean fixture for the code-size fragment: small functions,
// few parameters, flat control flow, short type, short file. None of the five
// threshold rules may fire here.

import Foundation

struct CompactType {
    let name: String
    let value: Int

    func doubled() -> Int {
        value * 2
    }

    func labeled(prefix: String) -> String {
        "\(prefix): \(name)"
    }
}

func combine(first: Int, second: Int) -> Int {
    first + second
}

func describe(_ item: CompactType) -> String {
    if item.value > 0 {
        return item.labeled(prefix: "positive")
    }
    return item.labeled(prefix: "non-positive")
}
