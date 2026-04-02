import SwiftUI

struct HistoryPanelView: View {
    @Bindable var viewModel: HistoryPanelViewModel
    var onDismiss: () -> Void = {}

    var body: some View {
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onKeyPress(.upArrow) {
            viewModel.moveSelection(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.moveSelection(direction: .down)
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.confirmPaste(mode: .original)
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .background(
            CmdShiftVKeyHandler {
                viewModel.confirmPaste(mode: .plainText)
            }
        )
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            TextField("検索...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
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
                            onDelete: { viewModel.deleteEntry(id: entry.id) }
                        )
                        .id(entry.id)
                        .onTapGesture {
                            viewModel.selectedIndex = index
                            viewModel.confirmPaste(mode: .original)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .onChange(of: viewModel.selectedIndex) { _, newValue in
                if newValue >= 0, newValue < viewModel.filteredEntries.count {
                    let id = viewModel.filteredEntries[newValue].id
                    withAnimation(.easeInOut(duration: 0.1)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
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
            Text("履歴がありません")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("テキストや画像をコピーすると\nここに表示されます")
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
            Text("一致する履歴がありません")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var hintBar: some View {
        HStack(spacing: 16) {
            hintLabel("↑↓", "選択")
            hintLabel("Enter", "ペースト")
            hintLabel("⌘⇧V", "プレーンテキスト")
            hintLabel("Esc", "閉じる")
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.03))
    }

    private func hintLabel(_ key: String, _ desc: String) -> some View {
        HStack(spacing: 2) {
            Text(key)
                .fontWeight(.medium)
            Text(desc)
        }
    }
}

// ⌘⇧V のキーイベントを NSEvent ローカルモニターで検出する
private struct CmdShiftVKeyHandler: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = CmdShiftVMonitorView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CmdShiftVMonitorView)?.action = action
    }
}

private class CmdShiftVMonitorView: NSView {
    var action: (() -> Void)?

    override var acceptsFirstResponder: Bool { false }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains([.command, .shift]),
           event.charactersIgnoringModifiers == "v" {
            action?()
        } else {
            super.keyDown(with: event)
        }
    }
}
