import AppKit
import SwiftUI

// バーチャルキーコード → 表示文字列
private let keyCodeMap: [UInt16: String] = [
    0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
    8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
    16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
    38: "J", 40: "K", 45: "N", 46: "M",
    18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
    22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
    122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
    98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
]

func shortcutLabel(keyCode: Int, modifiers: Int) -> String {
    guard keyCode != 0 else { return "未設定" }
    let mods = NSEvent.ModifierFlags(rawValue: UInt(bitPattern: modifiers))
    var s = ""
    if mods.contains(.control) { s += "⌃" }
    if mods.contains(.option)  { s += "⌥" }
    if mods.contains(.shift)   { s += "⇧" }
    if mods.contains(.command) { s += "⌘" }
    s += keyCodeMap[UInt16(keyCode)] ?? "?"
    return s
}

// MARK: - NSView

class KeyRecorderNSView: NSView {
    var keyCode: Int = 0
    var modifiers: Int = 0
    var isEnabled: Bool = true
    var onChange: ((Int, Int) -> Void)?

    private var isRecording = false

    override var acceptsFirstResponder: Bool { isEnabled }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.borderWidth = 1
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        isRecording = true
        needsDisplay = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return true
    }

    // 修飾キーありのイベント（Cmd+Q など）はここで先に捕捉し、
    // システムメニューに渡さないようにする
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return false }
        record(event: event)
        return true // 常に消費してシステムショートカットをブロック
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }
        record(event: event)
    }

    private func record(event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape → キャンセル
            window?.makeFirstResponder(nil)
        case 51, 117: // Delete/Forward Delete → クリア
            keyCode = 0
            modifiers = 0
            onChange?(0, 0)
            window?.makeFirstResponder(nil)
        default:
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard !mods.isEmpty else { return }
            keyCode = Int(event.keyCode)
            modifiers = Int(bitPattern: UInt(mods.rawValue))
            onChange?(keyCode, modifiers)
            window?.makeFirstResponder(nil)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let borderColor = isRecording
            ? NSColor.controlAccentColor
            : NSColor.separatorColor
        let bgColor = isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.08)
            : NSColor.controlBackgroundColor
        layer?.borderColor = borderColor.cgColor
        layer?.backgroundColor = bgColor.cgColor

        let label: String
        let color: NSColor
        if isRecording {
            label = "キーを押す…"
            color = .secondaryLabelColor
        } else if keyCode == 0 {
            label = "クリックして設定"
            color = .tertiaryLabelColor
        } else {
            label = shortcutLabel(keyCode: keyCode, modifiers: modifiers)
            color = isEnabled ? .labelColor : .secondaryLabelColor
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: color,
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let sz = str.size()
        str.draw(at: NSPoint(x: (bounds.width - sz.width) / 2,
                             y: (bounds.height - sz.height) / 2))
    }
}

// MARK: - SwiftUI Wrapper

struct KeyRecorderField: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    var isEnabled: Bool = true

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onChange = { [weak c = context.coordinator] k, m in
            c?.parent.keyCode = k
            c?.parent.modifiers = m
        }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        context.coordinator.parent = self
        nsView.keyCode = keyCode
        nsView.modifiers = modifiers
        nsView.isEnabled = isEnabled
        nsView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator {
        var parent: KeyRecorderField
        init(_ p: KeyRecorderField) { parent = p }
    }
}
