//
//  DocumentPicker.swift
//  TLMS-project-main
//
//  Document picker for resume upload
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var selectedData: Data?
    @Binding var selectedFileName: String?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType.pdf,
                UTType(filenameExtension: "doc")!,
                UTType(filenameExtension: "docx")!
            ],
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Check file size (max 10MB)
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
                    if fileSize > maxSize {
                        print("File too large: \(fileSize) bytes")
                        return
                    }
                }
                
                // Read file data
                let data = try Data(contentsOf: url)
                
                DispatchQueue.main.async {
                    self.parent.selectedURL = url
                    self.parent.selectedData = data
                    self.parent.selectedFileName = url.lastPathComponent
                    self.parent.dismiss()
                }
            } catch {
                print("Error reading file: \(error.localizedDescription)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
