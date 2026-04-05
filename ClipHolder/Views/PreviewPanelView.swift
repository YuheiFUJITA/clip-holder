import SwiftUI

struct PreviewPanelView: View {
    let entry: ClipboardHistoryEntry?

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
            Text(entry.textContent ?? "")
                .font(.system(size: 12))
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        case .image:
            if let imageData = entry.imageData, let nsImage = NSImage(data: imageData) {
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
    }

    private func metaLabel(for entry: ClipboardHistoryEntry) -> String {
        switch entry.dataType {
        case .text:
            let count = entry.textContent?.count ?? 0
            return "\(count)文字"
        case .image:
            if let data = entry.imageData, let img = NSImage(data: data) {
                let size = img.size
                return "\(Int(size.width))×\(Int(size.height))"
            }
            return "画像"
        }
    }
}
