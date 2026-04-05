import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showClipboardHistory = Self("showClipboardHistory", default: .init(.v, modifiers: [.option, .command]))
}
