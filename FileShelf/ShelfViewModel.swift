import Foundation

class ShelfViewModel: ObservableObject {
    @Published var items: [ShelfItem] = []

    func add(url: URL) {
        guard !items.contains(where: { $0.url == url }) else { return }
        items.append(ShelfItem(url: url))
    }

    func remove(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearAll() {
        items.removeAll()
    }
}
