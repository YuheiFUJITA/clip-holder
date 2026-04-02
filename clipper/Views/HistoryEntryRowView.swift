import SwiftUI
import AppKit

struct HistoryEntryRowView: View {
    let entry: ClipboardHistoryEntry
    let isSelected: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            subtypeIcon
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                previewContent
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .primary)

                HStack(spacing: 4) {
                    sourceAppIcon
                        .frame(width: 12, height: 12)

                    Text(metaText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.05))
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var subtypeIcon: some View {
        switch entry.dataType {
        case .text:
            switch entry.textSubtype ?? .plain {
            case .plain:
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("T")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.primary)
                    )
            case .url:
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
            case .richText:
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.purple.opacity(0.6))
                    .overlay(
                        Text("R")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        case .image:
            Image(systemName: "photo")
                .font(.system(size: 14))
                .foregroundStyle(.green)
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        switch entry.dataType {
        case .text:
            Text(entry.textContent ?? "")
        case .image:
            if let imageData = entry.imageData, let nsImage = NSImage(data: imageData) {
                HStack(spacing: 8) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text("画像")
                }
            } else {
                Text("画像")
            }
        }
    }

    @ViewBuilder
    private var sourceAppIcon: some View {
        if let bundleID = entry.sourceAppBundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            Image(nsImage: icon)
                .resizable()
        } else {
            Image(systemName: "app")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var metaText: String {
        let appName = entry.sourceAppName ?? "不明"
        let time = relativeTime(from: entry.timestamp)
        return "\(appName)  ·  \(time)"
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
