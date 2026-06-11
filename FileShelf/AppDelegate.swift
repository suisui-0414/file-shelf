import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var shelfWindow: ShelfPanel?
    let viewModel = ShelfViewModel()

    private var dragMonitors: [Any] = []
    private var autoShowedShelf = false
    private var dwellTimer: Timer?
    static let dwellInterval: TimeInterval = 0.5

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupShelfWindow()
        startDragMonitoring()
        shelfWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        dwellTimer?.invalidate()
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

        let panel = ShelfPanel(
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
            self?.dwellTimer?.invalidate()
            self?.autoShowedShelf = false
        }

        let onDrag = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            guard let self, !self.autoShowedShelf else { return }

            // ファイルドラッグでなければタイマーをキャンセル
            let pb = NSPasteboard(name: .drag)
            let fileTypes: [NSPasteboard.PasteboardType] = [.fileURL, .init("NSFilenamesPboardType")]
            guard pb.types?.contains(where: { fileTypes.contains($0) }) == true else {
                self.dwellTimer?.invalidate()
                return
            }

            // マウスが動くたびにタイマーをリセット
            // 0.5秒間イベントが来なければ「停止」と判定して開く
            self.dwellTimer?.invalidate()
            self.dwellTimer = Timer.scheduledTimer(
                withTimeInterval: AppDelegate.dwellInterval,
                repeats: false
            ) { [weak self] _ in
                guard let self, !self.autoShowedShelf else { return }
                self.autoShowedShelf = true
                self.shelfWindow?.makeKeyAndOrderFront(nil)
            }
        }

        let onUp = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.dwellTimer?.invalidate()
            self?.autoShowedShelf = false
        }

        dragMonitors = [onDown, onDrag, onUp].compactMap { $0 }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

class ShelfPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            orderOut(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}
