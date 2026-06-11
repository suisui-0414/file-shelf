import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var shelfWindow: ShelfPanel?
    private var preferencesWindow: NSWindow?
    let viewModel = ShelfViewModel()

    private var dragMonitors: [Any] = []
    private var autoShowedShelf = false
    private var dwellTimer: Timer?

    private var dwellInterval: TimeInterval {
        let v = UserDefaults.standard.double(forKey: "dwellInterval")
        return v > 0 ? v : 0.5
    }

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
        button.action = #selector(handleStatusItemClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "設定...", action: #selector(openPreferences), keyEquivalent: ""))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "FileShelf を終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        } else {
            toggleShelf()
        }
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            let hostingView = NSHostingView(rootView: PreferencesView())
            hostingView.sizingOptions = .intrinsicContentSize

            let window = NSWindow(
                contentRect: .zero,
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "FileShelf 設定"
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            window.center()
            preferencesWindow = window
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func startDragMonitoring() {
        let onDown = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.dwellTimer?.invalidate()
            self?.autoShowedShelf = false
        }

        let onDrag = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            guard let self, !self.autoShowedShelf else { return }

            let pb = NSPasteboard(name: .drag)
            let fileTypes: [NSPasteboard.PasteboardType] = [.fileURL, .init("NSFilenamesPboardType")]
            guard pb.types?.contains(where: { fileTypes.contains($0) }) == true else {
                self.dwellTimer?.invalidate()
                return
            }

            self.dwellTimer?.invalidate()
            self.dwellTimer = Timer.scheduledTimer(
                withTimeInterval: self.dwellInterval,
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
