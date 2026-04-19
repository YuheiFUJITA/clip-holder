import Foundation

enum SelectionDirection {
    case up
    case down
}

/// PreviewPanelView などのビューがコンテンツを非同期ロードするためのインターフェース。
/// 同期版 `loadContent(for:)` をビュー body 内で直接呼ぶと、選択変更のたびに
/// 同期 IO がメインスレッドで走るため、`.task(id:)` 経由でこちらを使う。
@MainActor
protocol PreviewContentLoading: AnyObject {
    func loadContentAsync(for entry: ClipboardHistoryEntry) async -> EntryContent
}

@Observable
@MainActor
final class HistoryPanelViewModel {
    var entries: [ClipboardHistoryEntry] = []
    var filteredEntries: [ClipboardHistoryEntry] = []
    var selectedIndex: Int = 0
    var searchQuery: String = ""
    var pasteError: String?
    /// キーボード操作で選択が動いた回数。View 側でスクロール追従のトリガーに使う。
    var keyboardNavTick: Int = 0
    /// パネル表示のたびに増えるカウンタ。View 側で検索フィールドへのフォーカス付与に使う。
    var panelShowTick: Int = 0

    private let store: ClipboardHistoryStoring
    private let pasteService: PasteExecuting
    private let panelService: PanelWindowManaging
    private let appSettings: AppSettings
    private let previousAppRecorder: (() -> Void)?

    init(
        store: ClipboardHistoryStoring,
        pasteService: PasteExecuting,
        panelService: PanelWindowManaging,
        appSettings: AppSettings,
        previousAppRecorder: (() -> Void)? = nil
    ) {
        self.store = store
        self.pasteService = pasteService
        self.panelService = panelService
        self.appSettings = appSettings
        self.showPreview = appSettings.showPreview
        self.previousAppRecorder = previousAppRecorder
    }

    var showPreview: Bool

    var isEmpty: Bool {
        entries.isEmpty
    }

    var isSearchEmpty: Bool {
        !searchQuery.isEmpty && filteredEntries.isEmpty
    }

    var selectedEntry: ClipboardHistoryEntry? {
        guard selectedIndex >= 0, selectedIndex < filteredEntries.count else { return nil }
        return filteredEntries[selectedIndex]
    }

    // MARK: - Actions

    func loadEntries() {
        entries = store.entries
        searchQuery = ""
        selectedIndex = 0
        pasteError = nil
        applyFilter()
    }

    func moveSelection(direction: SelectionDirection) {
        guard !filteredEntries.isEmpty else { return }
        switch direction {
        case .up:
            selectedIndex = max(0, selectedIndex - 1)
        case .down:
            selectedIndex = min(filteredEntries.count - 1, selectedIndex + 1)
        }
        keyboardNavTick &+= 1
    }

    func confirmPaste(mode: PasteMode) {
        guard selectedIndex >= 0, selectedIndex < filteredEntries.count else { return }
        let entry = filteredEntries[selectedIndex]
        // パネルを先に閉じてから貼り付ける（パネルがフォーカスを奪い返すのを防ぐ）
        panelService.hidePanel()
        Task {
            let content = loadContent(for: entry)
            let success = await pasteService.paste(content: content, entry: entry, mode: mode)
            if !success {
                pasteError = String(localized: "Paste failed. The item has been copied to the clipboard.")
            }
        }
    }

    func deleteEntry(id: UUID) {
        store.delete(id: id)
        entries = store.entries
        applyFilter()
        // 選択インデックスを範囲内に調整
        if !filteredEntries.isEmpty {
            selectedIndex = min(selectedIndex, filteredEntries.count - 1)
        } else {
            selectedIndex = 0
        }
    }

    func onPanelShow() {
        previousAppRecorder?()
        loadEntries()
        panelShowTick &+= 1
    }

    func togglePreview() {
        showPreview.toggle()
        appSettings.showPreview = showPreview
        panelService.resizePanel(showPreview: showPreview)
    }

    func loadContent(for entry: ClipboardHistoryEntry) -> EntryContent {
        store.loadContent(for: entry)
    }

    // MARK: - Private

    func applyFilter() {
        if searchQuery.isEmpty {
            filteredEntries = entries
        } else {
            filteredEntries = entries.filter { entry in
                guard let text = entry.previewText else { return false }
                return text.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        // 選択インデックスを範囲内に調整
        if filteredEntries.isEmpty {
            selectedIndex = 0
        } else {
            selectedIndex = min(selectedIndex, filteredEntries.count - 1)
        }
    }
}

// MARK: - PreviewContentLoading

extension HistoryPanelViewModel: PreviewContentLoading {
    /// 一度 yield してビュー描画を先行させてから同期 IO を実行する。
    /// `.task(id:)` 経由で呼ばれる前提なので、エントリ切替時には自動的に
    /// 旧 Task が cancel される（ファイル read 中の cancel は効かないが、
    /// 結果の反映は呼び出し側の `Task.isCancelled` チェックで防ぐ）。
    func loadContentAsync(for entry: ClipboardHistoryEntry) async -> EntryContent {
        await Task.yield()
        return store.loadContent(for: entry)
    }
}
