import Foundation

struct FileReferenceMetadata: Codable, Equatable {
    let filePath: String
    let fileName: String
    let fileSize: Int64?
    let fileUTI: String?

    var formattedSize: String {
        guard let size = fileSize else { return "不明" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
}
