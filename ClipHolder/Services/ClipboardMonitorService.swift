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

    private func isSVGContent(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("<svg") { return true }
        if trimmed.hasPrefix("<?xml"), trimmed.contains("<svg") { return true }
        return false
    }

    private func detectTextSubtype(pasteboard: NSPasteboard, text: String) -> (TextSubtype, Data?) {
        // SVG コンテンツの判定
        if isSVGContent(text) {
            return (.svg, nil)
        }

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

    private static let fileURLType = NSPasteboard.PasteboardType("public.file-url")
    private static let pdfType = NSPasteboard.PasteboardType("com.adobe.pdf")

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
        let types = pasteboard.types ?? []

        // 1. ファイル参照の処理（最優先: Finderコピーはテキストも含むため）
        if settings.saveFileData,
           types.contains(Self.fileURLType),
           let urlString = pasteboard.string(forType: Self.fileURLType),
           let fileURL = URL(string: urlString),
           fileURL.isFileURL {
            let filePath = fileURL.path
            let fm = FileManager.default

            let fileName = fileURL.lastPathComponent
            var fileSize: Int64?
            var fileUTI: String?

            if let attrs = try? fm.attributesOfItem(atPath: filePath) {
                fileSize = attrs[.size] as? Int64
            }
            if let uti = try? fileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                fileUTI = uti
            }

            let metadata = FileReferenceMetadata(
                filePath: filePath,
                fileName: fileName,
                fileSize: fileSize,
                fileUTI: fileUTI
            )

            let entry = ClipboardHistoryEntry(
                dataType: .file,
                sourceAppBundleID: sourceBundleID,
                sourceAppName: sourceName
            )
            let content = EntryContent(fileMetadata: metadata)
            store.add(entry, content: content, maxCount: settings.maxHistoryCount)
            print("[ClipboardMonitor] Added file entry: \(fileName). Store count: \(store.entries.count)")
            return
        }

        // 2. テキストデータの処理
        if settings.saveTextData,
           let text = pasteboard.string(forType: .string),
           !text.isEmpty {
            let (subtype, richData) = detectTextSubtype(pasteboard: pasteboard, text: text)

            let entry = ClipboardHistoryEntry(
                dataType: .text,
                textSubtype: subtype,
                sourceAppBundleID: sourceBundleID,
                sourceAppName: sourceName
            )

            var content = EntryContent()
            if subtype == .svg {
                content.svgContent = text
            } else {
                content.textContent = text
                content.richTextData = richData
            }

            store.add(entry, content: content, maxCount: settings.maxHistoryCount)
            print("[ClipboardMonitor] Added \(subtype) entry. Store count: \(store.entries.count)")
            return
        }

        // 3. PDFデータの処理
        if settings.savePDFData,
           let pdfData = pasteboard.data(forType: Self.pdfType) {
            let entry = ClipboardHistoryEntry(
                dataType: .pdf,
                sourceAppBundleID: sourceBundleID,
                sourceAppName: sourceName
            )
            let content = EntryContent(pdfData: pdfData)
            store.add(entry, content: content, maxCount: settings.maxHistoryCount)
            print("[ClipboardMonitor] Added PDF entry. Store count: \(store.entries.count)")
            return
        }

        // 4. 画像データの処理
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
                    sourceAppBundleID: sourceBundleID,
                    sourceAppName: sourceName
                )
                let content = EntryContent(imageData: data)
                store.add(entry, content: content, maxCount: settings.maxHistoryCount)
                print("[ClipboardMonitor] Added image entry. Store count: \(store.entries.count)")
            }
        } else {
            print("[ClipboardMonitor] No supported data found in pasteboard")
        }
    }
}
