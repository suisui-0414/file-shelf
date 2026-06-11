import SwiftUI

struct PreferencesView: View {
    @AppStorage("dwellInterval") private var dwellInterval: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ドラッグ時の自動表示")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Text("待機時間")
                Slider(value: $dwellInterval, in: 0.1...3.0, step: 0.1)
                Text(String(format: "%.1f 秒", dwellInterval))
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }

            Text("ファイルをドラッグ中にマウスを止めてから、シェルフが開くまでの時間です。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 360)
    }
}
