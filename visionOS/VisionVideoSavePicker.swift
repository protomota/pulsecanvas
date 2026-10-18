import SwiftUI
import UIKit

struct VisionVideoSaveRequest: Identifiable {
    let id = UUID()
    let url: URL
    init(url: URL) throws { try VisionVideoFile.validate(url); self.url = url }
}

/// Export the existing on-disk movie directly. Avoid SwiftUI's Transferable-to-
/// NSFileWrapper conversion, which aborts in setPreferredFilename on xrOS 27.
struct VisionVideoSavePicker: UIViewControllerRepresentable {
    let request: VisionVideoSaveRequest
    let completion: (Result<URL, Error>?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [request.url], asCopy: true)
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (Result<URL, Error>?) -> Void
        init(completion: @escaping (Result<URL, Error>?) -> Void) { self.completion = completion }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { completion(.failure(CocoaError(.fileWriteUnknown))); return }
            completion(.success(url))
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { completion(nil) }
    }
}
