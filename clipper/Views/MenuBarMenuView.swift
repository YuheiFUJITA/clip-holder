import SwiftUI

struct MenuBarMenuView: View {
    var body: some View {
        Button("クリップボード履歴を表示") {
            // クリップボード履歴ウィンドウが実装された後にここで表示する
        }
        .keyboardShortcut("v", modifiers: [.option, .command])

        Divider()

        SettingsLink {
            Text("設定...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Clipper を終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
