import SwiftUI

struct ShelfItemRow: View {
    let item: ShelfItem
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: item.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 24, height: 24)
            Text(item.name)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .onDrag {
            NSItemProvider(contentsOf: item.url) ?? NSItemProvider(object: item.url as NSURL)
        }
    }
}
