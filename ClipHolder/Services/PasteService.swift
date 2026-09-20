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

    /// 貼り付け先アプリが最前面になるのを待つ上限時間
    private static let activationTimeout: Duration = .seconds(1)
    /// 最前面確認のポーリング間隔
    private static let activationPollInterval: Duration = .milliseconds(20)
    /// 最前面になった後、キーウィンドウ/first responder の復帰を待つための猶予
    private static let postActivationDelay: Duration = .milliseconds(50)
    /// ⌘V の keyDown と keyUp の間隔（連続 post を取りこぼすアプリ対策）
    private static let keyEventGap: Duration = .milliseconds(10)

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
        guard let targetApp = previousApp, !targetApp.isTerminated else {
            return false
        }

        // 対象アプリが最前面になるまで待つ。
        // アクティブ化は非同期なので、固定時間待つだけでは ⌘V が
        // 自アプリや復帰前の対象アプリに届いて取りこぼされることがある。
        guard await activateAndWait(for: targetApp) else {
            print("[PasteService] Target app did not become frontmost: \(targetApp.localizedName ?? "unknown")")
            return false
        }

        // ⌘V キーイベントを送信
        await sendPasteKeyEvent()
        return true
    }

    // MARK: - Private

    private func isFrontmost(_ app: NSRunningApplication) -> Bool {
        NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
    }

    /// 対象アプリのアクティブ化を要求し、最前面になるまでポーリングで待つ。
    /// タイムアウトした場合は false を返す。
    private func activateAndWait(for targetApp: NSRunningApplication) async -> Bool {
        if !isFrontmost(targetApp) {
            // macOS 14 以降の協調的アクティベーションでは、アクティブなアプリが
            // 別アプリへ activation を譲る形 (activate(from:)) が正規ルート。
            // 自アプリがアクティブでない場合に備えて従来 API にもフォールバックする。
            var requested = targetApp.activate(from: .current, options: [])
            if !requested {
                requested = targetApp.activate(options: [])
            }
            if !requested {
                print("[PasteService] activate() request was not accepted")
            }
        }

        let clock = ContinuousClock()
        let deadline = clock.now + Self.activationTimeout
        while !isFrontmost(targetApp) {
            if clock.now >= deadline {
                return false
            }
            try? await Task.sleep(for: Self.activationPollInterval)
        }

        // アプリ切替直後はキーウィンドウ/first responder の復帰が追いついていないことがある
        try? await Task.sleep(for: Self.postActivationDelay)
        return true
    }

    private func sendPasteKeyEvent() async {
        let vKeyCode = CGKeyCode(kVK_ANSI_V)

        // combinedSessionState を使い、合成イベント送出中は物理キーボード入力を抑制する
        // （Enter キーがまだ押されたままの状態で ⌘V と混ざるのを防ぐ）
        let source = CGEventSource(stateID: .combinedSessionState)
        source?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        try? await Task.sleep(for: Self.keyEventGap)
        keyUp.post(tap: .cgSessionEventTap)
    }
}
