import SwiftUI
import Core

struct TagChipView: View {
    let tag: Tag
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 3) {
            Text(tag.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.accentColor)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.accentColor.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.accentColor.opacity(0.15))
        .clipShape(Capsule())
    }
}
