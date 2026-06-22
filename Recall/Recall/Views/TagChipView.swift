import SwiftUI
import Core

struct TagChipView: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.15))
            .clipShape(Capsule())
    }
}
