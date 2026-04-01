import Foundation

enum ClipboardDataType: String, Codable {
    case text
    case image
}

struct ClipboardHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let dataType: ClipboardDataType
    let textContent: String?
    let imageData: Data?
    let sourceAppBundleID: String?
    let sourceAppName: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        dataType: ClipboardDataType,
        textContent: String? = nil,
        imageData: Data? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType
        self.textContent = textContent
        self.imageData = imageData
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
    }
}
