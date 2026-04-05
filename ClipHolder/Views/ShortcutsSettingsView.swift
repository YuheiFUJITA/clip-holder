import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("グローバルショートカット") {
                KeyboardShortcuts.Recorder("クリップボード履歴を表示", name: .showClipboardHistory)
                    .accessibilityLabel("クリップボード履歴を表示するショートカットキー")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ShortcutsSettingsView()
        .frame(width: 450, height: 200)
}
