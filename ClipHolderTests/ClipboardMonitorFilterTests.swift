import Testing
import Foundation
@testable import ClipHolder

// テスト用のモック ClipboardHistoryStore
final class MockClipboardHistoryStore: ClipboardHistoryStoring {
    var entries: [ClipboardHistoryEntry] = []
    var addedEntries: [(ClipboardHistoryEntry, EntryContent)] = []
    var clearAllCalled = false

    // データ保持用（テスト時にloadで返す）
    private var textContents: [UUID: String] = [:]
    private var svgContents: [UUID: String] = [:]
    private var richTextDatas: [UUID: Data] = [:]
    private var imageDatas: [UUID: Data] = [:]
    private var pdfDatas: [UUID: Data] = [:]
    private var fileMetadatas: [UUID: FileReferenceMetadata] = [:]

    func add(_ entry: ClipboardHistoryEntry, content: EntryContent, maxCount: Int) {
        addedEntries.append((entry, content))

        // previewText を計算してエントリを保存
        let previewText: String?
        if let svg = content.svgContent {
            previewText = String(svg.prefix(200))
        } else if let text = content.textContent {
            previewText = String(text.prefix(200))
        } else if let meta = content.fileMetadata {
            previewText = "\(meta.fileName) — \(meta.formattedSize)"
        } else if content.pdfData != nil {
            previewText = "PDF"
        } else {
            previewText = nil
        }

        let finalEntry = ClipboardHistoryEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            dataType: entry.dataType,
            textSubtype: entry.textSubtype,
            previewText: previewText,
            sourceAppBundleID: entry.sourceAppBundleID,
            sourceAppName: entry.sourceAppName
        )

        entries.insert(finalEntry, at: 0)
        if entries.count > maxCount {
            entries = Array(entries.prefix(maxCount))
        }

        // データを保持
        if let text = content.textContent { textContents[entry.id] = text }
        if let svg = content.svgContent { svgContents[entry.id] = svg }
        if let rich = content.richTextData { richTextDatas[entry.id] = rich }
        if let img = content.imageData { imageDatas[entry.id] = img }
        if let pdf = content.pdfData { pdfDatas[entry.id] = pdf }
        if let meta = content.fileMetadata { fileMetadatas[entry.id] = meta }
    }

    func clearAll() {
        entries.removeAll()
        addedEntries.removeAll()
        textContents.removeAll()
        svgContents.removeAll()
        richTextDatas.removeAll()
        imageDatas.removeAll()
        clearAllCalled = true
    }

    func trimToCount(_ maxCount: Int) {
        if entries.count > maxCount {
            entries = Array(entries.prefix(maxCount))
        }
    }

    func delete(id: UUID) {
        entries.removeAll { $0.id == id }
        textContents.removeValue(forKey: id)
        svgContents.removeValue(forKey: id)
        richTextDatas.removeValue(forKey: id)
        imageDatas.removeValue(forKey: id)
        pdfDatas.removeValue(forKey: id)
        fileMetadatas.removeValue(forKey: id)
    }

    func loadTextContent(for entryID: UUID) -> String? { textContents[entryID] }
    func loadSVGContent(for entryID: UUID) -> String? { svgContents[entryID] }
    func loadRichTextData(for entryID: UUID) -> Data? { richTextDatas[entryID] }
    func loadImageData(for entryID: UUID) -> Data? { imageDatas[entryID] }
    func loadPDFData(for entryID: UUID) -> Data? { pdfDatas[entryID] }
    func loadFileMetadata(for entryID: UUID) -> FileReferenceMetadata? { fileMetadatas[entryID] }

    func loadContent(for entry: ClipboardHistoryEntry) -> EntryContent {
        let id = entry.id
        switch entry.dataType {
        case .text:
            switch entry.textSubtype {
            case .svg:
                return EntryContent(svgContent: svgContents[id])
            case .richText:
                return EntryContent(textContent: textContents[id], richTextData: richTextDatas[id])
            case .plain, .url, .none:
                return EntryContent(textContent: textContents[id])
            }
        case .image:
            return EntryContent(imageData: imageDatas[id])
        case .pdf:
            return EntryContent(pdfData: pdfDatas[id])
        case .file:
            return EntryContent(fileMetadata: fileMetadatas[id])
        }
    }

    // テスト用ヘルパー: データを直接セット
    func setTextContent(_ text: String, for id: UUID) { textContents[id] = text }
    func setSVGContent(_ svg: String, for id: UUID) { svgContents[id] = svg }
    func setImageData(_ data: Data, for id: UUID) { imageDatas[id] = data }
    func setPDFData(_ data: Data, for id: UUID) { pdfDatas[id] = data }
    func setFileMetadata(_ meta: FileReferenceMetadata, for id: UUID) { fileMetadatas[id] = meta }
}

@Suite
struct SettingsViewModelIntegrationTests {

    @Test @MainActor func initSyncsLoginItemStateOnFirstLaunch() {
        // UserDefaults に launchAtLogin が未設定の場合、システム状態で初期化
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
        let mockLogin = MockLoginItemService()
        mockLogin.isEnabled = true
        let settings = AppSettings()

        let _ = SettingsViewModel(
            settings: settings,
            loginItemService: mockLogin,
            accessibilityService: MockAccessibilityService()
        )

        #expect(settings.launchAtLogin == true)
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
    }

    @Test @MainActor func initPreservesUserSettingWhenAlreadySet() {
        // UserDefaults に明示的に保存済みの場合、ユーザー設定を維持
        UserDefaults.standard.set(true, forKey: "launchAtLogin")
        let mockLogin = MockLoginItemService()
        mockLogin.isEnabled = false
        let settings = AppSettings()

        let _ = SettingsViewModel(
            settings: settings,
            loginItemService: mockLogin,
            accessibilityService: MockAccessibilityService()
        )

        #expect(settings.launchAtLogin == true)
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
    }

    @Test @MainActor func confirmClearHistoryDelegatesToStore() {
        let mockStore = MockClipboardHistoryStore()
        let entry = ClipboardHistoryEntry(dataType: .text, previewText: "test")
        mockStore.entries = [entry]
        let vm = SettingsViewModel(
            settings: AppSettings(),
            loginItemService: MockLoginItemService(),
            accessibilityService: MockAccessibilityService(),
            historyStore: mockStore
        )
        vm.showDeleteConfirmation = true
        vm.confirmClearHistory()
        #expect(mockStore.clearAllCalled == true)
    }
}
