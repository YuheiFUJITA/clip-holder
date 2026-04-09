import Foundation

final class ClipboardDataFileManager {
    private let dataDirectory: URL

    init(baseDirectory: URL? = nil) {
        let base = baseDirectory ?? ClipboardDataFileManager.defaultBaseDirectory
        self.dataDirectory = base.appendingPathComponent("data")
        ensureDirectoryExists()
    }

    // MARK: - Write

    func saveTextContent(_ text: String, for entryID: UUID) {
        let url = fileURL(for: entryID, extension: "txt")
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    func saveSVGContent(_ svg: String, for entryID: UUID) {
        let url = fileURL(for: entryID, extension: "svg")
        try? svg.write(to: url, atomically: true, encoding: .utf8)
    }

    func saveRichTextData(_ data: Data, for entryID: UUID) {
        let url = fileURL(for: entryID, extension: "rtf")
        try? data.write(to: url, options: .atomic)
    }

    func saveImageData(_ data: Data, for entryID: UUID) {
        let url = fileURL(for: entryID, extension: "png")
        try? data.write(to: url, options: .atomic)
    }

    func savePDFData(_ data: Data, for entryID: UUID) {
        let url = fileURL(for: entryID, extension: "pdf")
        try? data.write(to: url, options: .atomic)
    }

    func saveFileMetadata(_ metadata: FileReferenceMetadata, for entryID: UUID) {
        let url = fileURL(for: entryID, extension: "json")
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Read

    func loadTextContent(for entryID: UUID) -> String? {
        let url = fileURL(for: entryID, extension: "txt")
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func loadSVGContent(for entryID: UUID) -> String? {
        let url = fileURL(for: entryID, extension: "svg")
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func loadRichTextData(for entryID: UUID) -> Data? {
        let url = fileURL(for: entryID, extension: "rtf")
        return try? Data(contentsOf: url)
    }

    func loadImageData(for entryID: UUID) -> Data? {
        let url = fileURL(for: entryID, extension: "png")
        return try? Data(contentsOf: url)
    }

    func loadPDFData(for entryID: UUID) -> Data? {
        let url = fileURL(for: entryID, extension: "pdf")
        return try? Data(contentsOf: url)
    }

    func loadFileMetadata(for entryID: UUID) -> FileReferenceMetadata? {
        let url = fileURL(for: entryID, extension: "json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(FileReferenceMetadata.self, from: data)
    }

    // MARK: - Delete

    func deleteDataFiles(for entryID: UUID) {
        let extensions = ["txt", "svg", "rtf", "png", "pdf", "json"]
        for ext in extensions {
            let url = fileURL(for: entryID, extension: ext)
            try? FileManager.default.removeItem(at: url)
        }
    }

    func deleteAllDataFiles() {
        try? FileManager.default.removeItem(at: dataDirectory)
        ensureDirectoryExists()
    }

    // MARK: - Private

    private static var defaultBaseDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("app.clip-holder")
    }

    private func fileURL(for entryID: UUID, extension ext: String) -> URL {
        dataDirectory.appendingPathComponent("\(entryID.uuidString).\(ext)")
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }
}
