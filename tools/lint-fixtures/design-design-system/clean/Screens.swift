import SwiftUI

enum Spacing { static let s: CGFloat = 8, m: CGFloat = 16 }
enum Radius { static let m: CGFloat = 12 }

struct ProfileHeader: View {
    let name: String
    let query: String

    var matches: Bool { name.lowercased().contains(query.lowercased()) }
    var currencyCode: String { "usd".uppercased() }

    var body: some View {
        VStack(spacing: 0) {
            Text("Recent").font(.headline)
            Text(name).font(.body)
                .foregroundStyle(Color.primary)
        }
        .padding(Spacing.m)
        .padding(.horizontal, Spacing.s)
        .padding(0)
        .background(RoundedRectangle(cornerRadius: Radius.m).fill(.background))
    }
}
