import SwiftUI

/// One key of a shortcut, drawn as a glass keycap.
struct Keycap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .frame(minWidth: 48, minHeight: 48)
            .padding(.horizontal, label.count > 1 ? 10 : 0)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}
