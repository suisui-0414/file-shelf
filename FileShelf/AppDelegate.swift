import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var shelfWindow: NSPanel?
    let viewModel = ShelfViewModel()

    private var dragMonitors: [Any] = []
    private var autoShowedShelf = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupShelfWindow()
        startDragMonitoring()
        shelfWindow?.orderFrontRegardless()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dragMonitors.forEach { NSEvent.removeMonitor($0) }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "tray.and.arrow.down", accessibilityDescription: "FileShelf")
        button.action = #selector(toggleShelf)
        button.target = self
    }

    private func setupShelfWindow() {
        let hostingView = NSHostingView(rootView: ContentView(viewModel: viewModel))

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 400),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "FileShelf"
        panel.contentView = hostingView
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.setFrameAutosaveName("FileShelfPanel")

        if panel.frame.origin == .zero, let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - panel.frame.width - 20
            let y = screen.visibleFrame.maxY - panel.frame.height - 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        shelfWindow = panel
    }

    @objc private func toggleShelf() {
        guard let panel = shelfWindow else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func startDragMonitoring() {
        let onDown = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.autoShowedShelf = false
        }

        let onDrag = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            guard let self, !self.autoShowedShelf else { return }
            guard self.isAtScreenEdge(NSEvent.mouseLocation) else { return }

            // ドラッグペーストボードにファイルURLが含まれているときだけ開く
            let pb = NSPasteboard(name: .drag)
            let fileTypes: [NSPasteboard.PasteboardType] = [.fileURL, .init("NSFilenamesPboardType")]
            guard pb.types?.contains(where: { fileTypes.contains($0) }) == true else { return }

            self.autoShowedShelf = true
            DispatchQueue.main.async { self.shelfWindow?.orderFrontRegardless() }
        }

        let onUp = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.autoShowedShelf = false
        }

        dragMonitors = [onDown, onDrag, onUp].compactMap { $0 }
    }

    private func isAtScreenEdge(_ location: NSPoint) -> Bool {
        NSScreen.screens.contains { screen in
            let f = screen.frame
            return location.x <= f.minX + 1
                || location.x >= f.maxX - 1
                || location.y <= f.minY + 1
                || location.y >= f.maxY - 1
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
