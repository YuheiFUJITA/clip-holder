import Foundation

enum ClipboardDataType: String, Codable {
    case text
    case image
    case pdf
    case file
}

enum TextSubtype: String, Codable {
    case plain
    case url
    case richText
    case svg
}

struct ClipboardHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let dataType: ClipboardDataType
    let textSubtype: TextSubtype?
    let previewText: String?
    let contentHash: String?
    let thumbnailData: Data?
    let sourceAppBundleID: String?
    let sourceAppName: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        dataType: ClipboardDataType,
        textSubtype: TextSubtype? = nil,
        previewText: String? = nil,
        contentHash: String? = nil,
        thumbnailData: Data? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType
        self.textSubtype = textSubtype
        self.previewText = previewText
        self.contentHash = contentHash
        self.thumbnailData = thumbnailData
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
    }

    // 旧フォーマットとの互換性を保つデコーダー
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        dataType = try container.decode(ClipboardDataType.self, forKey: .dataType)
        textSubtype = try container.decodeIfPresent(TextSubtype.self, forKey: .textSubtype)
            ?? (dataType == .text ? .plain : nil)
        contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
        thumbnailData = try container.decodeIfPresent(Data.self, forKey: .thumbnailData)
        sourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)

        // 旧フォーマット: previewText が無い場合は textContent から生成
        if let preview = try container.decodeIfPresent(String.self, forKey: .previewText) {
            previewText = preview
        } else if let textContent = try container.decodeIfPresent(String.self, forKey: .legacyTextContent) {
            previewText = String(textContent.prefix(200))
        } else {
            previewText = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(dataType, forKey: .dataType)
        try container.encodeIfPresent(textSubtype, forKey: .textSubtype)
        try container.encodeIfPresent(previewText, forKey: .previewText)
        try container.encodeIfPresent(contentHash, forKey: .contentHash)
        try container.encodeIfPresent(thumbnailData, forKey: .thumbnailData)
        try container.encodeIfPresent(sourceAppBundleID, forKey: .sourceAppBundleID)
        try container.encodeIfPresent(sourceAppName, forKey: .sourceAppName)
    }

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, dataType, textSubtype
        case previewText, contentHash, thumbnailData
        case sourceAppBundleID, sourceAppName
        // 旧フォーマットのキー（デコードのみ）
        case legacyTextContent = "textContent"
    }
}
