import Foundation

struct EntryContent {
    var textContent: String?
    var richTextData: Data?
    var imageData: Data?
    var svgContent: String?
    var pdfData: Data?
    var fileMetadata: FileReferenceMetadata?

    init(
        textContent: String? = nil,
        richTextData: Data? = nil,
        imageData: Data? = nil,
        svgContent: String? = nil,
        pdfData: Data? = nil,
        fileMetadata: FileReferenceMetadata? = nil
    ) {
        self.textContent = textContent
        self.richTextData = richTextData
        self.imageData = imageData
        self.svgContent = svgContent
        self.pdfData = pdfData
        self.fileMetadata = fileMetadata
    }
}
