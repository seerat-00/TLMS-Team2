//
//  MediaPicker.swift
//  TLMS-project-main
//
//  Media pickers for course content upload (Video, PDF, Keynote)
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

// MARK: - Video Picker (Photo Library & Files)

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var selectedFileName: String?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .movie,
                .video,
                .mpeg4Movie,
                .quickTimeMovie
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
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Check file size (max 100MB for videos)
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    let maxSize: Int64 = 100 * 1024 * 1024 // 100MB
                    if fileSize > maxSize {
                        print("Video file too large: \(fileSize) bytes")
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.selectedURL = url
                    self.parent.selectedFileName = url.lastPathComponent
                }
            } catch {
                print("Error reading video file: \(error.localizedDescription)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - PDF Picker

struct PDFPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var selectedFileName: String?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.pdf],
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
        let parent: PDFPicker
        
        init(_ parent: PDFPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Check file size (max 50MB for PDFs)
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    let maxSize: Int64 = 50 * 1024 * 1024 // 50MB
                    if fileSize > maxSize {
                        print("PDF file too large: \(fileSize) bytes")
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.selectedURL = url
                    self.parent.selectedFileName = url.lastPathComponent
                }
            } catch {
                print("Error reading PDF file: \(error.localizedDescription)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - Keynote/Presentation Picker

struct PresentationPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Binding var selectedFileName: String?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Support Keynote (.key), PowerPoint (.ppt, .pptx)
        var contentTypes: [UTType] = [.presentation]
        
        // Add Keynote-specific type
        if let keynoteType = UTType(filenameExtension: "key") {
            contentTypes.append(keynoteType)
        }
        
        // Add PowerPoint types
        if let pptType = UTType(filenameExtension: "ppt") {
            contentTypes.append(pptType)
        }
        if let pptxType = UTType(filenameExtension: "pptx") {
            contentTypes.append(pptxType)
        }
        
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: contentTypes,
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
        let parent: PresentationPicker
        
        init(_ parent: PresentationPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Check file size (max 100MB for presentations)
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    let maxSize: Int64 = 100 * 1024 * 1024 // 100MB
                    if fileSize > maxSize {
                        print("Presentation file too large: \(fileSize) bytes")
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.selectedURL = url
                    self.parent.selectedFileName = url.lastPathComponent
                }
            } catch {
                print("Error reading presentation file: \(error.localizedDescription)")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
