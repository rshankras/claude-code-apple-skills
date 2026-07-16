import SwiftUI

class SettingsModel: ObservableObject {
    @Published var isOn = false
}

func debugDump(_ values: [Int]) {
    print("values: \(values)")
    let first = values.first!
    let data = try! JSONEncoder().encode(first)
    _ = data
}
