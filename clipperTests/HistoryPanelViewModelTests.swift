import Testing
import Foundation
@testable import clipper

// MARK: - Mock Services

final class MockPasteService: PasteExecuting {
    var pastedEntries: [(ClipboardHistoryEntry, PasteMode)] = []
    var shouldSucceed = true

    func paste(entry: ClipboardHistoryEntry, mode: PasteMode) async -> Bool {
        pastedEntries.append((entry, mode))
        return shouldSucceed
    }
}

final class MockPanelWindowService: PanelWindowManaging {
    var isVisible: Bool = false
    var showCount = 0
    var hideCount = 0

    func showPanel() {
        isVisible = true
        showCount += 1
    }

    func hidePanel() {
        isVisible = false
        hideCount += 1
    }

    func togglePanel() {
        if isVisible { hidePanel() } else { showPanel() }
    }
}

// MARK: - Tests

@Suite
struct HistoryPanelViewModelTests {

    @MainActor private func makeViewModel(
        entries: [ClipboardHistoryEntry] = [],
        pasteService: MockPasteService = MockPasteService(),
        panelService: MockPanelWindowService = MockPanelWindowService()
    ) -> (HistoryPanelViewModel, MockClipboardHistoryStore, MockPasteService, MockPanelWindowService) {
        let store = MockClipboardHistoryStore()
        store.entries = entries
        let vm = HistoryPanelViewModel(
            store: store,
            pasteService: pasteService,
            panelService: panelService
        )
        return (vm, store, pasteService, panelService)
    }

    // MARK: - Load Entries

    @Test @MainActor func loadEntriesPopulatesFilteredEntries() {
        let entries = [
            ClipboardHistoryEntry(dataType: .text, textSubtype: .plain, textContent: "Hello"),
            ClipboardHistoryEntry(dataType: .text, textSubtype: .url, textContent: "https://example.com"),
        ]
        let (vm, _, _, _) = makeViewModel(entries: entries)
        vm.loadEntries()
        #expect(vm.filteredEntries.count == 2)
        #expect(vm.selectedIndex == 0)
    }

    @Test @MainActor func loadEntriesResetsSearchQuery() {
        let (vm, _, _, _) = makeViewModel(entries: [
            ClipboardHistoryEntry(dataType: .text, textContent: "test")
        ])
        vm.searchQuery = "something"
        vm.loadEntries()
        #expect(vm.searchQuery == "")
    }

    // MARK: - Search Filtering

    @Test @MainActor func searchQueryFiltersEntries() {
        let entries = [
            ClipboardHistoryEntry(dataType: .text, textSubtype: .plain, textContent: "Hello World"),
            ClipboardHistoryEntry(dataType: .text, textSubtype: .url, textContent: "https://example.com"),
            ClipboardHistoryEntry(dataType: .image, imageData: Data([0x89])),
        ]
        let (vm, _, _, _) = makeViewModel(entries: entries)
        vm.loadEntries()
        vm.searchQuery = "Hello"
        vm.applyFilter()
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries[0].textContent == "Hello World")
    }

    @Test @MainActor func searchQueryCaseInsensitive() {
        let (vm, _, _, _) = makeViewModel(entries: [
            ClipboardHistoryEntry(dataType: .text, textContent: "Hello World"),
        ])
        vm.loadEntries()
        vm.searchQuery = "hello"
        vm.applyFilter()
        #expect(vm.filteredEntries.count == 1)
    }

    @Test @MainActor func emptySearchShowsAll() {
        let (vm, _, _, _) = makeViewModel(entries: [
            ClipboardHistoryEntry(dataType: .text, textContent: "A"),
            ClipboardHistoryEntry(dataType: .text, textContent: "B"),
        ])
        vm.loadEntries()
        vm.searchQuery = "X"
        vm.applyFilter()
        #expect(vm.filteredEntries.isEmpty)
        vm.searchQuery = ""
        vm.applyFilter()
        #expect(vm.filteredEntries.count == 2)
    }

    @Test @MainActor func isSearchEmptyWhenQueryHasNoResults() {
        let (vm, _, _, _) = makeViewModel(entries: [
            ClipboardHistoryEntry(dataType: .text, textContent: "Hello"),
        ])
        vm.loadEntries()
        vm.searchQuery = "xyz"
        vm.applyFilter()
        #expect(vm.isSearchEmpty == true)
    }

    // MARK: - Selection

    @Test @MainActor func moveSelectionDown() {
        let (vm, _, _, _) = makeViewModel(entries: [
            ClipboardHistoryEntry(dataType: .text, textContent: "A"),
            ClipboardHistoryEntry(dataType: .text, textContent: "B"),
            ClipboardHistoryEntry(dataType: .text, textContent: "C"),
        ])
        vm.loadEntries()
        #expect(vm.selectedIndex == 0)
        vm.moveSelection(direction: .down)
        #expect(vm.selectedIndex == 1)
        vm.moveSelection(direction: .down)
        #expect(vm.selectedIndex == 2)
        vm.moveSelection(direction: .down)
        #expect(vm.selectedIndex == 2) // 下限で止まる
    }

    @Test @MainActor func moveSelectionUp() {
        let (vm, _, _, _) = makeViewModel(entries: [
            ClipboardHistoryEntry(dataType: .text, textContent: "A"),
            ClipboardHistoryEntry(dataType: .text, textContent: "B"),
        ])
        vm.loadEntries()
        vm.moveSelection(direction: .down)
        #expect(vm.selectedIndex == 1)
        vm.moveSelection(direction: .up)
        #expect(vm.selectedIndex == 0)
        vm.moveSelection(direction: .up)
        #expect(vm.selectedIndex == 0) // 上限で止まる
    }

    // MARK: - Delete

    @Test @MainActor func deleteEntryRemovesFromStoreAndUpdatesView() {
        let entry1 = ClipboardHistoryEntry(dataType: .text, textContent: "A")
        let entry2 = ClipboardHistoryEntry(dataType: .text, textContent: "B")
        let (vm, store, _, _) = makeViewModel(entries: [entry1, entry2])
        vm.loadEntries()
        #expect(vm.filteredEntries.count == 2)

        vm.deleteEntry(id: entry1.id)
        #expect(store.entries.count == 1)
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries[0].id == entry2.id)
    }

    @Test @MainActor func deleteAdjustsSelectedIndex() {
        let entries = [
            ClipboardHistoryEntry(dataType: .text, textContent: "A"),
            ClipboardHistoryEntry(dataType: .text, textContent: "B"),
        ]
        let (vm, _, _, _) = makeViewModel(entries: entries)
        vm.loadEntries()
        vm.moveSelection(direction: .down)
        #expect(vm.selectedIndex == 1)

        vm.deleteEntry(id: entries[1].id)
        #expect(vm.selectedIndex == 0) // 範囲内に調整
    }

    // MARK: - Empty State

    @Test @MainActor func isEmptyWhenNoEntries() {
        let (vm, _, _, _) = makeViewModel(entries: [])
        vm.loadEntries()
        #expect(vm.isEmpty == true)
    }

    @Test @MainActor func isNotEmptyWithEntries() {
        let (vm, _, _, _) = makeViewModel(entries: [
            ClipboardHistoryEntry(dataType: .text, textContent: "test")
        ])
        vm.loadEntries()
        #expect(vm.isEmpty == false)
    }
}

// MARK: - Store Delete Tests

@Suite
struct ClipboardHistoryStoreDeleteTests {
    @Test func deleteRemovesEntry() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ClipboardHistoryStore(directory: tempDir)
        let entry1 = ClipboardHistoryEntry(dataType: .text, textContent: "A")
        let entry2 = ClipboardHistoryEntry(dataType: .text, textContent: "B")
        store.add(entry1, maxCount: 10)
        store.add(entry2, maxCount: 10)
        #expect(store.entries.count == 2)

        store.delete(id: entry1.id)
        #expect(store.entries.count == 1)
        #expect(store.entries[0].id == entry2.id)

        // ディスクからリロードして永続化を確認
        let reloaded = ClipboardHistoryStore(directory: tempDir)
        #expect(reloaded.entries.count == 1)
        #expect(reloaded.entries[0].id == entry2.id)

        try? FileManager.default.removeItem(at: tempDir)
    }
}
