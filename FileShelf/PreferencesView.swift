import SwiftUI

struct PreferencesView: View {
    @AppStorage("dwellEnabled")      private var dwellEnabled      = true
    @AppStorage("dwellInterval")     private var dwellInterval     = 0.5
    @AppStorage("shortcutEnabled")   private var shortcutEnabled   = false
    @AppStorage("shortcutKeyCode")   private var shortcutKeyCode   = 0
    @AppStorage("shortcutModifiers") private var shortcutModifiers = 0

    var body: some View {
        Form {
            Section("ドラッグで開く") {
                Toggle("自動表示を有効にする", isOn: $dwellEnabled)
                HStack(spacing: 12) {
                    Text("待機時間")
                    Slider(value: $dwellInterval, in: 0.1...3.0, step: 0.1)
                        .disabled(!dwellEnabled)
                    Text(String(format: "%.1f 秒", dwellInterval))
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                        .foregroundColor(dwellEnabled ? .primary : .secondary)
                }
            }

            Section("キーボードショートカット") {
                Toggle("ショートカットキーを有効にする", isOn: $shortcutEnabled)
                HStack {
                    Text("ショートカット")
                    Spacer()
                    KeyRecorderField(
                        keyCode: $shortcutKeyCode,
                        modifiers: $shortcutModifiers,
                        isEnabled: shortcutEnabled
                    )
                    .frame(width: 150, height: 26)
                }
                Text("クリックしてからキーを押して設定。Deleteキーで解除。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding(.bottom, 8)
    }
}
