import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let pulseCanvasProject = UTType(exportedAs: "com.protomota.pulsecanvas.project", conformingTo: .json)
}
struct MobileProjectDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pulseCanvasProject, .json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count < 8_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
