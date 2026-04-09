import SwiftUI
import PDFKit

struct PreviewPanelView: View {
    let entry: ClipboardHistoryEntry?
    let content: EntryContent?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            HStack {
                Text("プレビュー")
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

            Divider()
                .padding(.horizontal, 16)

            // コンテンツ
            if let entry {
                ScrollView {
                    previewContent(for: entry)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Spacer()
                HStack {
                    Spacer()
                    Text("選択なし")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(width: 400)
        .background(.ultraThinMaterial)
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
        if let svgString = content?.svgContent,
           let svgData = svgString.data(using: .utf8),
           let nsImage = NSImage(data: svgData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text("SVGを表示できません")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var textPreview: some View {
        let displayText: String = {
            guard let text = content?.textContent else { return "" }
            if text.count > 10_000 {
                return String(text.prefix(10_000)) + "\n... (省略)"
            }
            return text
        }()
        Text(displayText)
            .font(.system(size: 12))
            .lineSpacing(6)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let imageData = content?.imageData, let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text("画像を表示できません")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var pdfPreview: some View {
        if let pdfData = content?.pdfData,
           let pdfDoc = PDFDocument(data: pdfData) {
            PDFKitView(document: pdfDoc)
                .frame(minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text("PDFを表示できません")
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

                    LabeledContent("サイズ") {
                        Text(meta.formattedSize)
                    }
                    .font(.system(size: 12))

                    if let uti = meta.fileUTI {
                        LabeledContent("種類") {
                            Text(uti)
                        }
                        .font(.system(size: 12))
                    }

                    LabeledContent("パス") {
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
                        Text("ファイルが見つかりません")
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
        } else {
            Text("ファイル情報を表示できません")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    private func metaLabel(for entry: ClipboardHistoryEntry) -> String {
        switch entry.dataType {
        case .text:
            if entry.textSubtype == .svg { return "SVG" }
            let count = content?.textContent?.count ?? entry.previewText?.count ?? 0
            return "\(count)文字"
        case .image:
            if let data = content?.imageData, let img = NSImage(data: data) {
                return "\(Int(img.size.width))×\(Int(img.size.height))"
            }
            return "画像"
        case .pdf:
            if let pdfData = content?.pdfData,
               let doc = PDFDocument(data: pdfData) {
                return "\(doc.pageCount)ページ"
            }
            return "PDF"
        case .file:
            return content?.fileMetadata?.formattedSize ?? "ファイル"
        }
    }
}

// PDFKit を SwiftUI で使うためのラッパー
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
        nsView.document = document
    }
}
