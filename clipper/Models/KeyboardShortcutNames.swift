// KeyboardShortcuts ライブラリ導入後に有効化する
// SPM で https://github.com/sindresorhus/KeyboardShortcuts を追加後、
// 以下のコメントを解除してください。

// import KeyboardShortcuts
//
// extension KeyboardShortcuts.Name {
//     static let showClipboardHistory = Self("showClipboardHistory", default: .init(.v, modifiers: [.option, .command]))
// }

import Foundation

/// KeyboardShortcuts ライブラリ導入前の仮定義
/// ショートカット設定タブではライブラリの Recorder ビューを使用するため、
/// ライブラリ導入後にこのファイルを上記のコメント解除版に置き換えること。
enum ClipperShortcuts {
    static let defaultShortcutDisplay = "⌥⌘V"
}
