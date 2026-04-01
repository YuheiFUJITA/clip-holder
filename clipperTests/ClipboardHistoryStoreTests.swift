import Testing
import Foundation
@testable import clipper

@Suite
struct ClipboardHistoryStoreTests {
    private func makeTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func makeEntry(text: String = "test", date: Date = Date()) -> ClipboardHistoryEntry {
        ClipboardHistoryEntry(timestamp: date, dataType: .text, textContent: text, sourceAppBundleID: "com.test", sourceAppName: "Test")
    }

    @Test func addEntryAndRetrieve() {
        let store = ClipboardHistoryStore(directory: makeTempDirectory())
        let entry = makeEntry(text: "hello")
        store.add(entry, maxCount: 50)
        #expect(store.entries.count == 1)
        #expect(store.entries[0].textContent == "hello")
    }

    @Test func addRespectsMaxCount() {
        let store = ClipboardHistoryStore(directory: makeTempDirectory())
        for i in 0..<10 {
            store.add(makeEntry(text: "item \(i)"), maxCount: 5)
        }
        #expect(store.entries.count == 5)
    }

    @Test func newestEntryIsFirst() {
        let store = ClipboardHistoryStore(directory: makeTempDirectory())
        let old = makeEntry(text: "old", date: Date(timeIntervalSinceNow: -100))
        let new = makeEntry(text: "new", date: Date())
        store.add(old, maxCount: 50)
        store.add(new, maxCount: 50)
        #expect(store.entries[0].textContent == "new")
    }

    @Test func clearAllRemovesEverything() {
        let store = ClipboardHistoryStore(directory: makeTempDirectory())
        store.add(makeEntry(), maxCount: 50)
        store.add(makeEntry(), maxCount: 50)
        store.clearAll()
        #expect(store.entries.isEmpty)
    }

    @Test func trimToCountRemovesOldEntries() {
        let store = ClipboardHistoryStore(directory: makeTempDirectory())
        for i in 0..<10 {
            store.add(makeEntry(text: "item \(i)"), maxCount: 100)
        }
        store.trimToCount(3)
        #expect(store.entries.count == 3)
    }

    @Test func trimToCountNoOpWhenUnderLimit() {
        let store = ClipboardHistoryStore(directory: makeTempDirectory())
        store.add(makeEntry(), maxCount: 50)
        store.trimToCount(10)
        #expect(store.entries.count == 1)
    }

    @Test func persistenceRoundTrip() {
        let dir = makeTempDirectory()
        let store1 = ClipboardHistoryStore(directory: dir)
        store1.add(makeEntry(text: "persisted"), maxCount: 50)

        let store2 = ClipboardHistoryStore(directory: dir)
        #expect(store2.entries.count == 1)
        #expect(store2.entries[0].textContent == "persisted")
    }

    @Test func corruptedFileReturnsEmpty() {
        let dir = makeTempDirectory()
        let filePath = dir.appendingPathComponent("clipboard_history.json")
        try? "not json".data(using: .utf8)?.write(to: filePath)

        let store = ClipboardHistoryStore(directory: dir)
        #expect(store.entries.isEmpty)
    }
}
