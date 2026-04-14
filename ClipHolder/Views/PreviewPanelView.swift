import SwiftUI
import AppKit
import PDFKit

struct PreviewPanelView: View {
    let entry: ClipboardHistoryEntry?
    let loader: any PreviewContentLoading

    // 現在ロード済みのコンテンツとデコード結果を @State でキャッシュする。
    // body 評価ごとの同期 IO や NSImage(data:)/PDFDocument(data:) の再生成を避ける。
    @State private var loadedEntryID: UUID? = nil
    @State private var content: EntryContent? = nil
    @State private var decodedImage: NSImage? = nil
    @State private var decodedPDF: PDFDocument? = nil
    @State private var decodedSVGImage: NSImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if entry != nil {
                Divider()
                    .padding(.horizontal, 16)
                contentArea
            } else {
                Spacer()
                HStack {
                    Spacer()
                    Text("No Selection")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(width: 400)
        .background(.ultraThinMaterial)
        .task(id: entry?.id) {
            await reload()
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text("Preview")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if let entry {
                Text(metaLabel(for: entry))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    /// 長文テキストは NSTextView (ReadOnlyTextView) が自前の NSScrollView を持つため、
    /// 外側の SwiftUI ScrollView をネストしないように分岐する。
    @ViewBuilder
    private var contentArea: some View {
        if let entry, useNativeScrolling(for: entry) {
            previewContent(for: entry)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let entry {
            ScrollView {
                previewContent(for: entry)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// 自前スクロールを持つビュー (NSTextView, PDFView) を表示する場合は外側 ScrollView を外す。
    private func useNativeScrolling(for entry: ClipboardHistoryEntry) -> Bool {
        switch entry.dataType {
        case .pdf:
            return true
        case .text:
            if entry.textSubtype == .svg { return false }
            let length = content?.textContent?.count ?? 0
            return length >= Self.nsTextViewThreshold
        default:
            return false
        }
    }

    @ViewBuilder
    private func previewContent(for entry: ClipboardHistoryEntry) -> some View {
        switch entry.dataType {
        case .text:
            if entry.textSubtype == .svg {
                svgPreview
            } else {
                textPreview
            }
        case .image:
            imagePreview
        case .pdf:
            pdfPreview
        case .file:
            filePreview
        }
    }

    @ViewBuilder
    private var svgPreview: some View {
        if let nsImage = decodedSVGImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if content == nil {
            // ロード中
            EmptyView()
        } else {
            Text("Unable to display SVG")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var textPreview: some View {
        let raw = content?.textContent ?? ""
        let truncated: String = raw.count > Self.textTruncationLimit
            ? String(raw.prefix(Self.textTruncationLimit)) + "\n" + String(localized: "... (truncated)")
            : raw

        if truncated.count >= Self.nsTextViewThreshold {
            // 長文は NSTextView に委譲（非連続レイアウトで重さを抑える）
            ReadOnlyTextView(text: truncated)
                .frame(minHeight: 200)
        } else {
            Text(truncated)
                .font(.system(size: 12))
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let nsImage = decodedImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if content == nil {
            EmptyView()
        } else {
            Text("Unable to display image")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var pdfPreview: some View {
        if let pdfDoc = decodedPDF {
            PDFKitView(document: pdfDoc)
                .frame(minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if content == nil {
            EmptyView()
        } else {
            Text("Unable to display PDF")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var filePreview: some View {
        if let meta = content?.fileMetadata {
            VStack(alignment: .leading, spacing: 16) {
                // ファイルアイコン
                HStack {
                    Spacer()
                    if meta.fileExists {
                        let icon = NSWorkspace.shared.icon(forFile: meta.filePath)
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 64, height: 64)
                    } else {
                        Image(systemName: "doc.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // ファイル情報
                VStack(alignment: .leading, spacing: 8) {
                    Text(meta.fileName)
                        .font(.system(size: 14, weight: .semibold))

                    LabeledContent("Size") {
                        Text(meta.formattedSize)
                    }
                    .font(.system(size: 12))

                    if let uti = meta.fileUTI {
                        LabeledContent("Type") {
                            Text(uti)
                        }
                        .font(.system(size: 12))
                    }

                    LabeledContent("Path") {
                        Text(meta.filePath)
                            .lineLimit(3)
                            .truncationMode(.middle)
                    }
                    .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)

                // ファイルが見つからない場合の警告
                if !meta.fileExists {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("File not found")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }
            }
        } else if content == nil {
            EmptyView()
        } else {
            Text("Unable to display file information")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    private func metaLabel(for entry: ClipboardHistoryEntry) -> String {
        switch entry.dataType {
        case .text:
            if entry.textSubtype == .svg { return "SVG" }
            let count = content?.textContent?.count ?? entry.previewText?.count ?? 0
            return String(localized: "\(count) characters")
        case .image:
            if let img = decodedImage {
                return "\(Int(img.size.width))×\(Int(img.size.height))"
            }
            return String(localized: "Image")
        case .pdf:
            if let doc = decodedPDF {
                return String(localized: "\(doc.pageCount) pages")
            }
            return "PDF"
        case .file:
            return content?.fileMetadata?.formattedSize ?? String(localized: "File")
        }
    }

    // MARK: - Loading

    private func reload() async {
        guard let entry else {
            resetState()
            return
        }
        // 同じエントリが再トリガーされた場合は skip
        if loadedEntryID == entry.id, content != nil {
            return
        }

        let snapshot = entry
        let loaded = await loader.loadContentAsync(for: snapshot)

        // ロード中にエントリが変わっていたら結果を破棄
        guard !Task.isCancelled, self.entry?.id == snapshot.id else { return }

        self.content = loaded
        self.loadedEntryID = snapshot.id
        decode(entry: snapshot, content: loaded)
    }

    private func decode(entry: ClipboardHistoryEntry, content: EntryContent) {
        // dataType に応じて必要なデコードだけを行い、結果を State に保存する
        decodedImage = nil
        decodedPDF = nil
        decodedSVGImage = nil

        switch entry.dataType {
        case .image:
            decodedImage = content.imageData.flatMap { NSImage(data: $0) }
        case .pdf:
            decodedPDF = content.pdfData.flatMap { PDFDocument(data: $0) }
        case .text where entry.textSubtype == .svg:
            if let svg = content.svgContent,
               let data = svg.data(using: .utf8) {
                decodedSVGImage = NSImage(data: data)
            }
        default:
            break
        }
    }

    private func resetState() {
        content = nil
        loadedEntryID = nil
        decodedImage = nil
        decodedPDF = nil
        decodedSVGImage = nil
    }

    // MARK: - Constants

    /// この文字数を超えるテキストプレビューは NSTextView に委譲する。
    /// SwiftUI Text + lineSpacing は全文レイアウトを行うため、長文だと選択直後にカクつく。
    private static let nsTextViewThreshold: Int = 3_000

    /// この文字数で末尾を切り捨てる。NSTextView 側でも一定以上は重くなるため上限を設ける。
    private static let textTruncationLimit: Int = 50_000
}

// MARK: - PDFKit ラッパー

private struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = false
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        // document が同一インスタンスなら再代入を避ける（再レイアウトを防ぐ）
        if nsView.document !== document {
            nsView.document = document
        }
    }
}

// MARK: - 長文表示用 NSTextView ラッパー

/// 大きなテキストを SwiftUI Text で描画すると全文レイアウトが走り、選択直後にカクつく。
/// NSTextView の非連続レイアウトを使い、可視範囲のみ描画させる。
private struct ReadOnlyTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true

        guard let textView = scroll.documentView as? NSTextView else { return scroll }
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.font = .systemFont(ofSize: 12)
        textView.textContainer?.lineFragmentPadding = 0
        textView.layoutManager?.allowsNonContiguousLayout = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        applyText(textView, text)
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            applyText(textView, text)
        }
    }

    private func applyText(_ textView: NSTextView, _ text: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph
        ]
        textView.textStorage?.setAttributedString(
            NSAttributedString(string: text, attributes: attributes)
        )
    }
}
