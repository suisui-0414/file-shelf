import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: ShelfViewModel
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            if viewModel.items.isEmpty {
                emptyStateView
            } else {
                itemListView
            }
        }
        .frame(minWidth: 220, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        .background(isDropTargeted ? Color.accentColor.opacity(0.12) : Color.clear)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var headerView: some View {
        HStack {
            Text("FileShelf")
                .font(.headline)
            Spacer()
            Button("Clear All") {
                viewModel.clearAll()
            }
            .buttonStyle(.plain)
            .foregroundColor(viewModel.items.isEmpty ? .secondary : .red)
            .disabled(viewModel.items.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("ファイルをドロップ")
                .foregroundColor(.secondary)
                .font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemListView: some View {
        List {
            ForEach(viewModel.items) { item in
                ShelfItemRow(item: item) {
                    viewModel.remove(item)
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
            }
        }
        .listStyle(.plain)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    DispatchQueue.main.async {
                        self.viewModel.add(url: url)
                    }
                }
                handled = true
            }
        }
        return handled
    }
}
