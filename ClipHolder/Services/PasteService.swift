import Foundation
import AppKit
import Carbon.HIToolbox

enum PasteMode {
    case original
    case plainText
}

protocol PasteExecuting {
    func paste(content: EntryContent, entry: ClipboardHistoryEntry, mode: PasteMode) async -> Bool
}

final class PasteService: PasteExecuting {
    private var previousApp: NSRunningApplication?

    func recordPreviousApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    func paste(content: EntryContent, entry: ClipboardHistoryEntry, mode: PasteMode) async -> Bool {
        // クリップボードにデータを設定
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch entry.dataType {
        case .text:
            if entry.textSubtype == .svg {
                guard let svg = content.svgContent else { return false }
                pasteboard.setString(svg, forType: .string)
            } else {
                guard let text = content.textContent else { return false }
                if mode == .original, let richData = content.richTextData {
                    pasteboard.setData(richData, forType: .rtf)
                    pasteboard.setString(text, forType: .string)
                } else {
                    pasteboard.setString(text, forType: .string)
                }
            }
        case .image:
            guard let imageData = content.imageData else { return false }
            pasteboard.setData(imageData, forType: .png)
        case .pdf:
            guard let pdfData = content.pdfData else { return false }
            let pdfType = NSPasteboard.PasteboardType("com.adobe.pdf")
            pasteboard.setData(pdfData, forType: pdfType)
        case .file:
            guard let meta = content.fileMetadata else { return false }
            let fileURL = URL(fileURLWithPath: meta.filePath)
            pasteboard.writeObjects([fileURL as NSURL])
        }

        // 直前のアプリを前面に切り替え
        guard let targetApp = previousApp else {
            return false
        }
        targetApp.activate(options: .activateIgnoringOtherApps)

        // アプリ切替の安定化のための遅延
        try? await Task.sleep(for: .milliseconds(100))

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
