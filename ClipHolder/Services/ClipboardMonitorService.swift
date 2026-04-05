import Foundation
import AppKit

protocol ClipboardMonitoring {
    func startMonitoring()
    func stopMonitoring()
}

final class ClipboardMonitorService: ClipboardMonitoring {
    private let settings: AppSettings
    private let store: ClipboardHistoryStoring
    private var timer: Timer?
    private var lastChangeCount: Int
    private let selfBundleID: String

    init(settings: AppSettings, store: ClipboardHistoryStoring) {
        self.settings = settings
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount
        self.selfBundleID = Bundle.main.bundleIdentifier ?? "app.clip-holder"
    }

    func startMonitoring() {
        stopMonitoring()
        let newTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
        print("[ClipboardMonitor] Monitoring started. Initial changeCount: \(lastChangeCount)")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Private

    private func detectTextSubtype(pasteboard: NSPasteboard, text: String) -> (TextSubtype, Data?) {
        // RTF または HTML 型が存在する場合はリッチテキスト
        let types = pasteboard.types ?? []
        if types.contains(.rtf) || types.contains(.html) {
            let richData = pasteboard.data(forType: .rtf) ?? pasteboard.data(forType: .html)
            return (.richText, richData)
        }

        // URL 型の存在、またはテキスト内容が URL パターンに一致する場合
        if types.contains(.URL) {
            return (.url, nil)
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), let scheme = url.scheme,
           ["http", "https", "ftp"].contains(scheme.lowercased()) {
            return (.url, nil)
        }

        return (.plain, nil)
    }

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        print("[ClipboardMonitor] changeCount changed to \(currentCount)")

        // 自アプリからの書き込みを除外
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier == selfBundleID {
            print("[ClipboardMonitor] Skipped: self-app (\(selfBundleID))")
            return
        }

        // コピー元アプリ情報を取得
        let sourceApp = NSWorkspace.shared.frontmostApplication
        let sourceBundleID = sourceApp?.bundleIdentifier
        let sourceName = sourceApp?.localizedName
        print("[ClipboardMonitor] Source: \(sourceName ?? "unknown") (\(sourceBundleID ?? "nil"))")

        // 除外アプリチェック
        if let bundleID = sourceBundleID {
            let excludedIDs = settings.excludedApps.map { $0.id }
            if excludedIDs.contains(bundleID) {
                print("[ClipboardMonitor] Skipped: excluded app")
                return
            }
        }

        let pasteboard = NSPasteboard.general
        print("[ClipboardMonitor] saveTextData=\(settings.saveTextData), saveImageData=\(settings.saveImageData)")

        // テキストデータの処理
        if settings.saveTextData,
           let text = pasteboard.string(forType: .string),
           !text.isEmpty {
            let (subtype, richData) = detectTextSubtype(pasteboard: pasteboard, text: text)
            let entry = ClipboardHistoryEntry(
                dataType: .text,
                textSubtype: subtype,
                textContent: text,
                richTextData: richData,
                sourceAppBundleID: sourceBundleID,
                sourceAppName: sourceName
            )
            store.add(entry, maxCount: settings.maxHistoryCount)
            print("[ClipboardMonitor] Added text entry. Store count: \(store.entries.count)")
            return
        }

        // 画像データの処理
        if settings.saveImageData,
           let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            // TIFF を PNG に変換
            let pngData: Data?
            if let bitmapRep = NSBitmapImageRep(data: imageData) {
                pngData = bitmapRep.representation(using: .png, properties: [:])
            } else {
                pngData = imageData
            }

            if let data = pngData {
                let entry = ClipboardHistoryEntry(
                    dataType: .image,
                    imageData: data,
                    sourceAppBundleID: sourceBundleID,
                    sourceAppName: sourceName
                )
                store.add(entry, maxCount: settings.maxHistoryCount)
                print("[ClipboardMonitor] Added image entry. Store count: \(store.entries.count)")
            }
        } else {
            print("[ClipboardMonitor] No text or image data found in pasteboard")
        }
    }
}
