import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Global Shortcuts") {
                KeyboardShortcuts.Recorder(String(localized: "Show Clipboard History"), name: .showClipboardHistory)
                    .accessibilityLabel("Shortcut to show clipboard history")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ShortcutsSettingsView()
        .frame(width: 450, height: 200)
}
