import SwiftUI
import AppKit

struct HistoryEntryRowView: View {
    let entry: ClipboardHistoryEntry
    let isSelected: Bool
    let onPaste: () -> Void
    let onDelete: () -> Void

    @State private var isHovered: Bool = false

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
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                actionButtons
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundFill)
        )
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var backgroundFill: Color {
        if isSelected {
            return Color.accentColor.opacity(0.6)
        } else if isHovered {
            return Color.primary.opacity(0.12)
        } else {
            return Color.primary.opacity(0.05)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            Button(action: onPaste) {
                Text("Paste")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.25))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Paste"))

            Button(action: onDelete) {
                Text("Delete")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.55))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Delete"))
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
            case .svg:
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.6))
                    .overlay(
                        Text("SVG")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        case .image:
            Image(systemName: "photo")
                .font(.system(size: 14))
                .foregroundStyle(.green)
        case .pdf:
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.7))
                .overlay(
                    Text("PDF")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                )
        case .file:
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.6))
                .overlay(
                    Image(systemName: "doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                )
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        switch entry.dataType {
        case .text:
            Text(entry.previewText?.previewLine ?? "")
        case .image:
            if let thumbData = entry.thumbnailData, let nsImage = NSImage(data: thumbData) {
                HStack(spacing: 8) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text("Image")
                }
            } else {
                Text("Image")
            }
        case .pdf:
            Text(entry.previewText ?? "PDF")
        case .file:
            Text(entry.previewText ?? String(localized: "File"))
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
        let appName = entry.sourceAppName ?? String(localized: "Unknown")
        let time = relativeTime(from: entry.timestamp)
        return "\(appName)  ·  \(time)"
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private extension String {
    var previewLine: String {
        let searchRange = prefix(min(count, 500))
        for line in searchRange.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return String(searchRange).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
