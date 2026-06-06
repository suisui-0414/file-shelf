import AppKit
import Foundation

struct ShelfItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    var name: String { url.lastPathComponent }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}
