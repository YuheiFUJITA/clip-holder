import Foundation
import AppKit
import Carbon.HIToolbox

enum PasteMode {
    case original
    case plainText
}

protocol PasteExecuting {
    func paste(entry: ClipboardHistoryEntry, mode: PasteMode) async -> Bool
}

final class PasteService: PasteExecuting {
    private var previousApp: NSRunningApplication?

    func recordPreviousApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    func paste(entry: ClipboardHistoryEntry, mode: PasteMode) async -> Bool {
        // クリップボードにデータを設定
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch entry.dataType {
        case .text:
            guard let text = entry.textContent else { return false }
            if mode == .original, let richData = entry.richTextData {
                // 元形式: RTF データとプレーンテキストの両方を設定
                pasteboard.setData(richData, forType: .rtf)
                pasteboard.setString(text, forType: .string)
            } else {
                // プレーンテキストモード: テキスト文字列のみ
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            guard let imageData = entry.imageData else { return false }
            pasteboard.setData(imageData, forType: .png)
        }

        // 直前のアプリを前面に切り替え
        guard let targetApp = previousApp else {
            return false
        }
        targetApp.activate()

        // アプリ切替の安定化のための遅延
        try? await Task.sleep(for: .milliseconds(50))

        // ⌘V キーイベントを送信
        sendPasteKeyEvent()
        return true
    }

    // MARK: - Private

    private func sendPasteKeyEvent() {
        let vKeyCode: CGKeyCode = CGKeyCode(kVK_ANSI_V)

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
