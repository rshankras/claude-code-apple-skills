import SwiftUI

struct ProfileHeader: View {
    let name: String

    var body: some View {
        VStack {
            Text("Recent")
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.6)
            Text(name.uppercased())
            Text("Bio")
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
        }
        .padding(16)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.95)))
        .cornerRadius(8)
    }
}
