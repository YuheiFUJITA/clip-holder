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
        self.selfBundleID = Bundle.main.bundleIdentifier ?? "dev.fujita.clipper"
    }

    func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Private

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        // 自アプリからの書き込みを除外
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier == selfBundleID {
            return
        }

        // コピー元アプリ情報を取得
        let sourceApp = NSWorkspace.shared.frontmostApplication
        let sourceBundleID = sourceApp?.bundleIdentifier
        let sourceName = sourceApp?.localizedName

        // 除外アプリチェック
        if let bundleID = sourceBundleID {
            let excludedIDs = settings.excludedApps.map { $0.id }
            if excludedIDs.contains(bundleID) {
                return
            }
        }

        let pasteboard = NSPasteboard.general

        // テキストデータの処理
        if settings.saveTextData,
           let text = pasteboard.string(forType: .string),
           !text.isEmpty {
            let entry = ClipboardHistoryEntry(
                dataType: .text,
                textContent: text,
                sourceAppBundleID: sourceBundleID,
                sourceAppName: sourceName
            )
            store.add(entry, maxCount: settings.maxHistoryCount)
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
            }
        }
    }
}
