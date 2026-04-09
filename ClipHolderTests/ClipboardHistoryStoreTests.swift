import Testing
import Foundation
@testable import ClipHolder

@Suite
struct ClipboardHistoryStoreTests {
    private func makeTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func makeEntry(text: String = "test", date: Date = Date()) -> (ClipboardHistoryEntry, EntryContent) {
        let entry = ClipboardHistoryEntry(
            timestamp: date,
            dataType: .text,
            textSubtype: .plain,
            sourceAppBundleID: "com.test",
            sourceAppName: "Test"
        )
        let content = EntryContent(textContent: text)
        return (entry, content)
    }

    private func makeImageEntry(data: Data, date: Date = Date()) -> (ClipboardHistoryEntry, EntryContent) {
        let entry = ClipboardHistoryEntry(
            timestamp: date,
            dataType: .image,
            sourceAppBundleID: "com.test",
            sourceAppName: "Test"
        )
        let content = EntryContent(imageData: data)
        return (entry, content)
    }

    @Test func addEntryAndRetrieve() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (entry, content) = makeEntry(text: "hello")
        store.add(entry, content: content, maxCount: 50)
        #expect(store.entries.count == 1)
        #expect(store.entries[0].previewText == "hello")
        // データファイルから読み込み
        #expect(store.loadTextContent(for: entry.id) == "hello")
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func addRespectsMaxCount() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        for i in 0..<10 {
            let (entry, content) = makeEntry(text: "item \(i)")
            store.add(entry, content: content, maxCount: 5)
        }
        #expect(store.entries.count == 5)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func newestEntryIsFirst() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (oldEntry, oldContent) = makeEntry(text: "old", date: Date(timeIntervalSinceNow: -100))
        let (newEntry, newContent) = makeEntry(text: "new", date: Date())
        store.add(oldEntry, content: oldContent, maxCount: 50)
        store.add(newEntry, content: newContent, maxCount: 50)
        #expect(store.entries[0].previewText == "new")
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func clearAllRemovesEverything() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (entry1, content1) = makeEntry()
        let (entry2, content2) = makeEntry(text: "other")
        store.add(entry1, content: content1, maxCount: 50)
        store.add(entry2, content: content2, maxCount: 50)
        store.clearAll()
        #expect(store.entries.isEmpty)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func trimToCountRemovesOldEntries() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        for i in 0..<10 {
            let (entry, content) = makeEntry(text: "item \(i)")
            store.add(entry, content: content, maxCount: 100)
        }
        store.trimToCount(3)
        #expect(store.entries.count == 3)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func trimToCountNoOpWhenUnderLimit() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (entry, content) = makeEntry()
        store.add(entry, content: content, maxCount: 50)
        store.trimToCount(10)
        #expect(store.entries.count == 1)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func persistenceRoundTrip() {
        let dir = makeTempDirectory()
        let store1 = ClipboardHistoryStore(directory: dir)
        let (entry, content) = makeEntry(text: "persisted")
        store1.add(entry, content: content, maxCount: 50)

        let store2 = ClipboardHistoryStore(directory: dir)
        #expect(store2.entries.count == 1)
        #expect(store2.entries[0].previewText == "persisted")
        // データファイルも読める
        #expect(store2.loadTextContent(for: entry.id) == "persisted")
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func corruptedFileReturnsEmpty() {
        let dir = makeTempDirectory()
        let filePath = dir.appendingPathComponent("history.json")
        try? "not json".data(using: .utf8)?.write(to: filePath)

        let store = ClipboardHistoryStore(directory: dir)
        #expect(store.entries.isEmpty)
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - 重複防止テスト

    @Test func duplicateTextEntryRemovesOldAndKeepsNew() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (oldEntry, oldContent) = makeEntry(text: "same", date: Date(timeIntervalSinceNow: -100))
        let (newEntry, newContent) = makeEntry(text: "same", date: Date())
        store.add(oldEntry, content: oldContent, maxCount: 50)
        store.add(newEntry, content: newContent, maxCount: 50)
        #expect(store.entries.count == 1)
        #expect(store.entries[0].id == newEntry.id)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func differentTextEntriesAreKept() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (entry1, content1) = makeEntry(text: "alpha")
        let (entry2, content2) = makeEntry(text: "beta")
        store.add(entry1, content: content1, maxCount: 50)
        store.add(entry2, content: content2, maxCount: 50)
        #expect(store.entries.count == 2)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func textAndImageWithSameContentAreNotDuplicates() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (textEntry, textContent) = makeEntry(text: "data")
        let (imageEntry, imageContent) = makeImageEntry(data: Data("data".utf8))
        store.add(textEntry, content: textContent, maxCount: 50)
        store.add(imageEntry, content: imageContent, maxCount: 50)
        #expect(store.entries.count == 2)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func duplicateImageEntryRemovesOldAndKeepsNew() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let (oldEntry, oldContent) = makeImageEntry(data: imageData, date: Date(timeIntervalSinceNow: -100))
        let (newEntry, newContent) = makeImageEntry(data: imageData, date: Date())
        store.add(oldEntry, content: oldContent, maxCount: 50)
        store.add(newEntry, content: newContent, maxCount: 50)
        #expect(store.entries.count == 1)
        #expect(store.entries[0].id == newEntry.id)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func differentImageEntriesAreKept() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (entry1, content1) = makeImageEntry(data: Data([0x01]))
        let (entry2, content2) = makeImageEntry(data: Data([0x02]))
        store.add(entry1, content: content1, maxCount: 50)
        store.add(entry2, content: content2, maxCount: 50)
        #expect(store.entries.count == 2)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func duplicateRemovalRespectsMaxCount() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        for i in 0..<5 {
            let (entry, content) = makeEntry(text: "item \(i)")
            store.add(entry, content: content, maxCount: 5)
        }
        // 既存の "item 0" と同一内容を追加 → 古いエントリが削除され、新しいものが先頭に
        let (entry, content) = makeEntry(text: "item 0")
        store.add(entry, content: content, maxCount: 5)
        #expect(store.entries.count == 5)
        #expect(store.entries[0].previewText == "item 0")
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - マイグレーションテスト

    @Test func migratesLegacyFormat() {
        let dir = makeTempDirectory()

        // 旧フォーマットのJSONを作成
        let legacyJSON = """
        [
            {
                "id": "11111111-1111-1111-1111-111111111111",
                "timestamp": "2026-01-01T00:00:00Z",
                "dataType": "text",
                "textSubtype": "plain",
                "textContent": "legacy text",
                "sourceAppBundleID": "com.test",
                "sourceAppName": "Test"
            }
        ]
        """
        let legacyURL = dir.appendingPathComponent("clipboard_history.json")
        try? legacyJSON.data(using: .utf8)?.write(to: legacyURL)

        let store = ClipboardHistoryStore(directory: dir)
        #expect(store.entries.count == 1)
        #expect(store.entries[0].previewText == "legacy text")
        // データファイルが作成されている
        let legacyID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        #expect(store.loadTextContent(for: legacyID) == "legacy text")
        // 旧ファイルがバックアップされている
        #expect(!FileManager.default.fileExists(atPath: legacyURL.path))
        #expect(FileManager.default.fileExists(atPath: legacyURL.appendingPathExtension("bak").path))

        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - データファイルテスト

    @Test func deleteEntryRemovesDataFiles() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let (entry, content) = makeEntry(text: "to delete")
        store.add(entry, content: content, maxCount: 50)
        #expect(store.loadTextContent(for: entry.id) == "to delete")

        store.delete(id: entry.id)
        #expect(store.entries.isEmpty)
        #expect(store.loadTextContent(for: entry.id) == nil)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func svgEntryStoredAndRetrieved() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let entry = ClipboardHistoryEntry(
            dataType: .text,
            textSubtype: .svg,
            sourceAppBundleID: "com.figma",
            sourceAppName: "Figma"
        )
        let svgString = "<svg xmlns=\"http://www.w3.org/2000/svg\"><rect width=\"100\" height=\"100\"/></svg>"
        let content = EntryContent(svgContent: svgString)
        store.add(entry, content: content, maxCount: 50)

        #expect(store.entries.count == 1)
        #expect(store.entries[0].textSubtype == .svg)
        #expect(store.loadSVGContent(for: entry.id) == svgString)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func pdfEntryStoredAndRetrieved() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let entry = ClipboardHistoryEntry(
            dataType: .pdf,
            sourceAppBundleID: "com.apple.Preview",
            sourceAppName: "Preview"
        )
        let pdfData = Data([0x25, 0x50, 0x44, 0x46]) // %PDF header
        let content = EntryContent(pdfData: pdfData)
        store.add(entry, content: content, maxCount: 50)

        #expect(store.entries.count == 1)
        #expect(store.entries[0].dataType == .pdf)
        #expect(store.loadPDFData(for: entry.id) == pdfData)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test func fileEntryStoredAndRetrieved() {
        let dir = makeTempDirectory()
        let store = ClipboardHistoryStore(directory: dir)
        let entry = ClipboardHistoryEntry(
            dataType: .file,
            sourceAppBundleID: "com.apple.finder",
            sourceAppName: "Finder"
        )
        let metadata = FileReferenceMetadata(
            filePath: "/Users/test/Documents/test.txt",
            fileName: "test.txt",
            fileSize: 1024,
            fileUTI: "public.plain-text"
        )
        let content = EntryContent(fileMetadata: metadata)
        store.add(entry, content: content, maxCount: 50)

        #expect(store.entries.count == 1)
        #expect(store.entries[0].dataType == .file)
        #expect(store.entries[0].previewText?.contains("test.txt") == true)
        let loaded = store.loadFileMetadata(for: entry.id)
        #expect(loaded?.filePath == "/Users/test/Documents/test.txt")
        #expect(loaded?.fileName == "test.txt")
        #expect(loaded?.fileSize == 1024)
        try? FileManager.default.removeItem(at: dir)
    }
}
