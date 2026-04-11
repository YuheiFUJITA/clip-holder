import SwiftUI

struct MenuBarMenuView: View {
    var onShowHistory: () -> Void = {}
    var onCheckForUpdates: () -> Void = {}
    var canCheckForUpdates: Bool = true

    var body: some View {
        Button("Show Clipboard History") {
            onShowHistory()
        }
        .keyboardShortcut("v", modifiers: [.option, .command])

        Divider()

        Button("Check for Updates…") {
            onCheckForUpdates()
        }
        .disabled(!canCheckForUpdates)

        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Clip Holder") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
