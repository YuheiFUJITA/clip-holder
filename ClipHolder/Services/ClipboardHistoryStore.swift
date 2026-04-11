import Foundation
import AppKit
import PDFKit

protocol ClipboardHistoryStoring {
    var entries: [ClipboardHistoryEntry] { get }
    func add(_ entry: ClipboardHistoryEntry, content: EntryContent, maxCount: Int)
    func clearAll()
    func trimToCount(_ maxCount: Int)
    func delete(id: UUID)

    // オンデマンドデータ読み込み
    func loadTextContent(for entryID: UUID) -> String?
    func loadSVGContent(for entryID: UUID) -> String?
    func loadRichTextData(for entryID: UUID) -> Data?
    func loadImageData(for entryID: UUID) -> Data?
    func loadPDFData(for entryID: UUID) -> Data?
    func loadFileMetadata(for entryID: UUID) -> FileReferenceMetadata?
}

final class ClipboardHistoryStore: ClipboardHistoryStoring {
    private(set) var entries: [ClipboardHistoryEntry] = []
    private let metadataFileURL: URL
    private let fileManager: ClipboardDataFileManager
    private let directory: URL

    init(directory: URL? = nil) {
        let dir = directory ?? ClipboardHistoryStore.defaultDirectory
        self.directory = dir
        self.metadataFileURL = dir.appendingPathComponent("history.json")
        self.fileManager = ClipboardDataFileManager(baseDirectory: dir)
        ensureDirectoryExists(dir)
        migrateIfNeeded()
        loadFromDisk()
    }

    func add(_ entry: ClipboardHistoryEntry, content: EntryContent, maxCount: Int) {
        // previewText と contentHash を算出
        let previewText = generatePreviewText(from: content, entry: entry)
        let contentHash = generateContentHash(from: content, entry: entry)
        let thumbnailData = generateThumbnail(from: content)

        let finalEntry = ClipboardHistoryEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            dataType: entry.dataType,
            textSubtype: entry.textSubtype,
            previewText: previewText,
            contentHash: contentHash,
            thumbnailData: thumbnailData,
            sourceAppBundleID: entry.sourceAppBundleID,
            sourceAppName: entry.sourceAppName
        )

        // 重複検出: contentHash で比較
        if let hash = contentHash {
            let removedIDs = entries.filter {
                $0.dataType == entry.dataType && $0.contentHash == hash
            }.map { $0.id }
            entries.removeAll { removedIDs.contains($0.id) }
            for id in removedIDs {
                fileManager.deleteDataFiles(for: id)
            }
        }

        // データファイルを書き出し
        saveContentFiles(content: content, entryID: entry.id, entry: entry)

        entries.insert(finalEntry, at: 0)
        if entries.count > maxCount {
            let removed = Array(entries.suffix(from: maxCount))
            entries = Array(entries.prefix(maxCount))
            for old in removed {
                fileManager.deleteDataFiles(for: old.id)
            }
        }
        saveMetadata()
    }

    func clearAll() {
        entries.removeAll()
        fileManager.deleteAllDataFiles()
        saveMetadata()
    }

    func trimToCount(_ maxCount: Int) {
        guard entries.count > maxCount else { return }
        let removed = Array(entries.suffix(from: maxCount))
        entries = Array(entries.prefix(maxCount))
        for old in removed {
            fileManager.deleteDataFiles(for: old.id)
        }
        saveMetadata()
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
        fileManager.deleteDataFiles(for: id)
        saveMetadata()
    }

    // MARK: - Data Loading

    func loadTextContent(for entryID: UUID) -> String? {
        fileManager.loadTextContent(for: entryID)
    }

    func loadSVGContent(for entryID: UUID) -> String? {
        fileManager.loadSVGContent(for: entryID)
    }

    func loadRichTextData(for entryID: UUID) -> Data? {
        fileManager.loadRichTextData(for: entryID)
    }

    func loadImageData(for entryID: UUID) -> Data? {
        fileManager.loadImageData(for: entryID)
    }

    func loadPDFData(for entryID: UUID) -> Data? {
        fileManager.loadPDFData(for: entryID)
    }

    func loadFileMetadata(for entryID: UUID) -> FileReferenceMetadata? {
        fileManager.loadFileMetadata(for: entryID)
    }

    // MARK: - Private

    private static var defaultDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("app.clip-holder")
    }

    private func ensureDirectoryExists(_ directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: metadataFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: metadataFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([ClipboardHistoryEntry].self, from: data)
        } catch {
            entries = []
        }
    }

    private func saveMetadata() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: metadataFileURL, options: .atomic)
        } catch {
            // サイレントフォールバック: インメモリのみ保持
        }
    }

    private func generatePreviewText(from content: EntryContent, entry: ClipboardHistoryEntry) -> String? {
        switch entry.dataType {
        case .text:
            if let svg = content.svgContent { return String(svg.prefix(200)) }
            if let text = content.textContent { return String(text.prefix(200)) }
            return nil
        case .image:
            return nil
        case .pdf:
            if let pdfData = content.pdfData,
               let doc = PDFDocument(data: pdfData) {
                return String(localized: "PDF — \(doc.pageCount) pages")
            }
            return "PDF"
        case .file:
            if let meta = content.fileMetadata {
                return "\(meta.fileName) — \(meta.formattedSize)"
            }
            return nil
        }
    }

    private func generateContentHash(from content: EntryContent, entry: ClipboardHistoryEntry) -> String? {
        switch entry.dataType {
        case .text:
            if let svg = content.svgContent { return svg.sha256Hash }
            if let text = content.textContent { return text.sha256Hash }
            return nil
        case .image:
            return content.imageData?.sha256Hash
        case .pdf:
            return content.pdfData?.sha256Hash
        case .file:
            return content.fileMetadata?.filePath.sha256Hash
        }
    }

    private func generateThumbnail(from content: EntryContent) -> Data? {
        guard let imageData = content.imageData,
              let image = NSImage(data: imageData) else { return nil }

        let thumbSize = NSSize(width: 72, height: 48)
        let thumbImage = NSImage(size: thumbSize)
        thumbImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        thumbImage.unlockFocus()

        guard let tiffData = thumbImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            return nil
        }
        return jpegData
    }

    private func saveContentFiles(content: EntryContent, entryID: UUID, entry: ClipboardHistoryEntry) {
        if let svg = content.svgContent {
            fileManager.saveSVGContent(svg, for: entryID)
        }
        if let text = content.textContent {
            fileManager.saveTextContent(text, for: entryID)
        }
        if let richData = content.richTextData {
            fileManager.saveRichTextData(richData, for: entryID)
        }
        if let imageData = content.imageData {
            fileManager.saveImageData(imageData, for: entryID)
        }
        if let pdfData = content.pdfData {
            fileManager.savePDFData(pdfData, for: entryID)
        }
        if let fileMeta = content.fileMetadata {
            fileManager.saveFileMetadata(fileMeta, for: entryID)
        }
    }

    // MARK: - Migration

    private func migrateIfNeeded() {
        let legacyFileURL = directory.appendingPathComponent("clipboard_history.json")
        guard FileManager.default.fileExists(atPath: legacyFileURL.path),
              !FileManager.default.fileExists(atPath: metadataFileURL.path) else { return }

        print("[ClipboardHistoryStore] Migrating from legacy format...")

        do {
            let data = try Data(contentsOf: legacyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let legacyEntries = try decoder.decode([LegacyClipboardHistoryEntry].self, from: data)

            var newEntries: [ClipboardHistoryEntry] = []
            for legacy in legacyEntries {
                let content = EntryContent(
                    textContent: legacy.textContent,
                    richTextData: legacy.richTextData,
                    imageData: legacy.imageData
                )
                saveContentFiles(
                    content: content,
                    entryID: legacy.id,
                    entry: ClipboardHistoryEntry(
                        id: legacy.id,
                        timestamp: legacy.timestamp,
                        dataType: legacy.dataType,
                        textSubtype: legacy.textSubtype,
                        sourceAppBundleID: legacy.sourceAppBundleID,
                        sourceAppName: legacy.sourceAppName
                    )
                )

                let previewText: String?
                if legacy.dataType == .text, let text = legacy.textContent {
                    previewText = String(text.prefix(200))
                } else {
                    previewText = nil
                }

                let contentHash: String?
                switch legacy.dataType {
                case .text:
                    contentHash = legacy.textContent?.sha256Hash
                case .image:
                    contentHash = legacy.imageData?.sha256Hash
                case .pdf, .file:
                    contentHash = nil
                }

                let thumbnailData = generateThumbnail(from: content)

                newEntries.append(ClipboardHistoryEntry(
                    id: legacy.id,
                    timestamp: legacy.timestamp,
                    dataType: legacy.dataType,
                    textSubtype: legacy.textSubtype,
                    previewText: previewText,
                    contentHash: contentHash,
                    thumbnailData: thumbnailData,
                    sourceAppBundleID: legacy.sourceAppBundleID,
                    sourceAppName: legacy.sourceAppName
                ))
            }

            entries = newEntries
            saveMetadata()

            // 旧ファイルをバックアップ
            let backupURL = legacyFileURL.appendingPathExtension("bak")
            try? FileManager.default.moveItem(at: legacyFileURL, to: backupURL)
            print("[ClipboardHistoryStore] Migration complete. \(newEntries.count) entries migrated.")
        } catch {
            print("[ClipboardHistoryStore] Migration failed: \(error)")
        }
    }
}

// 旧フォーマットのデコード用
private struct LegacyClipboardHistoryEntry: Codable {
    let id: UUID
    let timestamp: Date
    let dataType: ClipboardDataType
    let textSubtype: TextSubtype?
    let textContent: String?
    let imageData: Data?
    let richTextData: Data?
    let sourceAppBundleID: String?
    let sourceAppName: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        dataType = try container.decode(ClipboardDataType.self, forKey: .dataType)
        textSubtype = try container.decodeIfPresent(TextSubtype.self, forKey: .textSubtype)
            ?? (dataType == .text ? .plain : nil)
        textContent = try container.decodeIfPresent(String.self, forKey: .textContent)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        richTextData = try container.decodeIfPresent(Data.self, forKey: .richTextData)
        sourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
    }
}
