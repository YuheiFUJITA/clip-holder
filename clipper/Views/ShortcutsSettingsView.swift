import SwiftUI

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("グローバルショートカット") {
                HStack {
                    Text("クリップボード履歴を表示")
                    Spacer()
                    // KeyboardShortcuts ライブラリ導入後:
                    // KeyboardShortcuts.Recorder("", name: .showClipboardHistory)
                    Text(ClipperShortcuts.defaultShortcutDisplay)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        .accessibilityLabel("クリップボード履歴を表示するショートカットキー")
                        .accessibilityValue(ClipperShortcuts.defaultShortcutDisplay)
                }

                Text("KeyboardShortcuts ライブラリを SPM で追加後、ショートカットの録画・変更が可能になります。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ShortcutsSettingsView()
        .frame(width: 450, height: 200)
}
