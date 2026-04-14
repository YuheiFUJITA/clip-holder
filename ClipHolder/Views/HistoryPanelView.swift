import SwiftUI

struct HistoryPanelView: View {
    @Bindable var viewModel: HistoryPanelViewModel
    var onDismiss: () -> Void = {}

    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            // 左パネル: 履歴リスト
            VStack(spacing: 0) {
                // 検索フィールド
                searchField
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // エントリリストまたは空状態
                if viewModel.isEmpty {
                    emptyState
                } else if viewModel.isSearchEmpty {
                    noResultsState
                } else {
                    entryList
                }

                Spacer(minLength: 0)

                // ヒントバー
                hintBar
            }
            .frame(width: 360, height: 480)

            // 区切り線 + 右プレビューパネル
            if !viewModel.isEmpty {
                Divider()

                PreviewPanelView(
                    entry: viewModel.selectedEntry,
                    loader: viewModel
                )
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: viewModel.searchQuery) {
            viewModel.applyFilter()
        }
        .onChange(of: viewModel.panelShowTick) { _, _ in
            isSearchFieldFocused = true
        }
        .onAppear {
            isSearchFieldFocused = true
        }
        .background(
            PanelKeyHandler(
                onUpArrow: { viewModel.moveSelection(direction: .up) },
                onDownArrow: { viewModel.moveSelection(direction: .down) },
                onReturn: { viewModel.confirmPaste(mode: .original) },
                onCmdShiftV: { viewModel.confirmPaste(mode: .plainText) },
                onEscape: { onDismiss() },
                onDeleteEntry: {
                    guard viewModel.searchQuery.isEmpty,
                          let entry = viewModel.selectedEntry else {
                        return false
                    }
                    viewModel.deleteEntry(id: entry.id)
                    return true
                }
            )
        )
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            TextField("Search…", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFieldFocused)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.06))
        )
    }

    private var entryList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(viewModel.filteredEntries.enumerated()), id: \.element.id) { index, entry in
                        HistoryEntryRowView(
                            entry: entry,
                            isSelected: index == viewModel.selectedIndex,
                            onPaste: {
                                viewModel.selectedIndex = index
                                viewModel.confirmPaste(mode: .original)
                            },
                            onDelete: { viewModel.deleteEntry(id: entry.id) }
                        )
                        .id(entry.id)
                        .onTapGesture {
                            viewModel.selectedIndex = index
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .onChange(of: viewModel.keyboardNavTick) { _, _ in
                let index = viewModel.selectedIndex
                guard index >= 0, index < viewModel.filteredEntries.count else { return }
                let id = viewModel.filteredEntries[index].id
                withAnimation(.easeInOut(duration: 0.1)) {
                    proxy.scrollTo(id)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clipboard")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No History")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Copy text or images\nto see them here")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No matching history")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var hintBar: some View {
        HStack(spacing: 16) {
            hintLabel("↑↓", "Select")
            hintLabel("Enter", "Paste")
            hintLabel("⌘⇧V", "Plain Text")
            hintLabel("Esc", "Close")
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.03))
    }

    private func hintLabel(_ key: LocalizedStringKey, _ desc: LocalizedStringKey) -> some View {
        HStack(spacing: 2) {
            Text(key)
                .fontWeight(.medium)
            Text(desc)
        }
    }
}

/// Enter / ⌘⇧V / Esc のキーイベントを NSEvent ローカルモニターで検出する
/// IMEの変換確定中（markedText がある状態）ではEnterキーを無視する
private struct PanelKeyHandler: NSViewRepresentable {
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    let onReturn: () -> Void
    let onCmdShiftV: () -> Void
    let onEscape: () -> Void
    /// Delete キー押下時のハンドラ。true を返すとイベントを消費する。
    let onDeleteEntry: () -> Bool

    func makeNSView(context: Context) -> PanelKeyMonitorView {
        let view = PanelKeyMonitorView()
        view.onUpArrow = onUpArrow
        view.onDownArrow = onDownArrow
        view.onReturn = onReturn
        view.onCmdShiftV = onCmdShiftV
        view.onEscape = onEscape
        view.onDeleteEntry = onDeleteEntry
        return view
    }

    func updateNSView(_ nsView: PanelKeyMonitorView, context: Context) {
        nsView.onUpArrow = onUpArrow
        nsView.onDownArrow = onDownArrow
        nsView.onReturn = onReturn
        nsView.onCmdShiftV = onCmdShiftV
        nsView.onEscape = onEscape
        nsView.onDeleteEntry = onDeleteEntry
    }
}

private class PanelKeyMonitorView: NSView {
    var onUpArrow: (() -> Void)?
    var onDownArrow: (() -> Void)?
    var onReturn: (() -> Void)?
    var onCmdShiftV: (() -> Void)?
    var onEscape: (() -> Void)?
    var onDeleteEntry: (() -> Bool)?
    private var localMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKeyEvent(event)
        }
    }

    private func stopMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        // ⌘⇧V
        if event.modifierFlags.contains([.command, .shift]),
           event.charactersIgnoringModifiers == "v" {
            onCmdShiftV?()
            return nil
        }

        // Escape
        if event.keyCode == 53 {
            onEscape?()
            return nil
        }

        // ↑矢印
        if event.keyCode == 126 {
            onUpArrow?()
            return nil
        }

        // ↓矢印
        if event.keyCode == 125 {
            onDownArrow?()
            return nil
        }

        // Enter（IME変換確定中は無視）
        if event.keyCode == 36 || event.keyCode == 76 {
            // 現在のウィンドウの firstResponder にマークドテキスト（IME入力中）があるか確認
            if let responder = self.window?.firstResponder as? NSTextInputClient,
               responder.hasMarkedText() {
                // IME変換確定のためイベントをそのまま通す
                return event
            }
            onReturn?()
            return nil
        }

        // Delete / Forward Delete（検索欄に入力がある場合はそのまま通す）
        if event.keyCode == 51 || event.keyCode == 117 {
            if onDeleteEntry?() == true {
                return nil
            }
            return event
        }

        return event
    }

    deinit {
        stopMonitoring()
    }
}
