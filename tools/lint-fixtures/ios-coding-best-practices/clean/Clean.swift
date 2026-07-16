import SwiftUI
import os

@Observable
final class SettingsModel {
    var isOn = false
}

private let logger = Logger(subsystem: "app", category: "settings")

func debugDump(_ values: [Int]) {
    logger.debug("values: \(values.count)")
    guard let first = values.first else { return }
    if let data = try? JSONEncoder().encode(first) {
        _ = data
    }
}
