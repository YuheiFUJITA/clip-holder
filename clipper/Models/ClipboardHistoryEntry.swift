import Foundation

enum ClipboardDataType: String, Codable {
    case text
    case image
}

enum TextSubtype: String, Codable {
    case plain
    case url
    case richText
}

struct ClipboardHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let dataType: ClipboardDataType
    let textSubtype: TextSubtype?
    let textContent: String?
    let imageData: Data?
    let richTextData: Data?
    let sourceAppBundleID: String?
    let sourceAppName: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        dataType: ClipboardDataType,
        textSubtype: TextSubtype? = nil,
        textContent: String? = nil,
        imageData: Data? = nil,
        richTextData: Data? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType
        self.textSubtype = textSubtype
        self.textContent = textContent
        self.imageData = imageData
        self.richTextData = richTextData
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        dataType = try container.decode(ClipboardDataType.self, forKey: .dataType)
        textSubtype = try container.decodeIfPresent(TextSubtype.self, forKey: .textSubtype) ?? (dataType == .text ? .plain : nil)
        textContent = try container.decodeIfPresent(String.self, forKey: .textContent)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        richTextData = try container.decodeIfPresent(Data.self, forKey: .richTextData)
        sourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
    }
}
