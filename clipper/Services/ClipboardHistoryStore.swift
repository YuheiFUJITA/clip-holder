import Foundation

protocol ClipboardHistoryStoring {
    var entries: [ClipboardHistoryEntry] { get }
    func add(_ entry: ClipboardHistoryEntry, maxCount: Int)
    func clearAll()
    func trimToCount(_ maxCount: Int)
    func delete(id: UUID)
}

final class ClipboardHistoryStore: ClipboardHistoryStoring {
    private(set) var entries: [ClipboardHistoryEntry] = []
    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? ClipboardHistoryStore.defaultDirectory
        self.fileURL = dir.appendingPathComponent("clipboard_history.json")
        ensureDirectoryExists(dir)
        loadFromDisk()
    }

    func add(_ entry: ClipboardHistoryEntry, maxCount: Int) {
        // 同一内容の既存エントリを削除（重複防止）
        entries.removeAll { existing in
            if existing.dataType != entry.dataType { return false }
            switch entry.dataType {
            case .text:
                return existing.textContent == entry.textContent
            case .image:
                return existing.imageData == entry.imageData
            }
        }

        entries.insert(entry, at: 0)
        if entries.count > maxCount {
            entries = Array(entries.prefix(maxCount))
        }
        saveToDisk()
    }

    func clearAll() {
        entries.removeAll()
        saveToDisk()
    }

    func trimToCount(_ maxCount: Int) {
        guard entries.count > maxCount else { return }
        entries = Array(entries.prefix(maxCount))
        saveToDisk()
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
        saveToDisk()
    }

    // MARK: - Private

    private static var defaultDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("dev.fujita.clipper")
    }

    private func ensureDirectoryExists(_ directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([ClipboardHistoryEntry].self, from: data)
        } catch {
            entries = []
        }
    }

    private func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // サイレントフォールバック: インメモリのみ保持
        }
    }
}
