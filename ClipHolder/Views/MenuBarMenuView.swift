import SwiftUI

struct MenuBarMenuView: View {
    var onShowHistory: () -> Void = {}
    var onCheckForUpdates: () -> Void = {}
    var canCheckForUpdates: Bool = true

    var body: some View {
        Button("クリップボード履歴を表示") {
            onShowHistory()
        }
        .keyboardShortcut("v", modifiers: [.option, .command])

        Divider()

        Button("アップデートを確認...") {
            onCheckForUpdates()
        }
        .disabled(!canCheckForUpdates)

        SettingsLink {
            Text("設定...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Clip Holder を終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
