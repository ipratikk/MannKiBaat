//
//  MemoryItemEditView.swift
//  MannKiBaat
//

import SwiftUI
import SwiftData
import SharedModels
import PhotosUI
import UIKit
import ImageIO

// MARK: - Helpers
fileprivate func extractDateFromImageData(_ data: Data) -> Date? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
          let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String
    else { return nil }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return formatter.date(from: dateString)
}

@MainActor
public struct MemoryItemEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MemoryViewModel
    
    @Bindable var lane: MemoryLane
    @Bindable var item: MemoryItem
    
    @State private var title: String
    @State private var details: String
    @State private var date: Date
    
    @State private var pickedImage: PhotosPickerItem?
    @State private var imageData: Data?
    
    @State private var showCamera = false
    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var showDeleteConfirmation = false
    @State private var showCropper = false
    @State private var tempImage: UIImage?
    
    public init(item: MemoryItem, lane: MemoryLane, viewModel: MemoryViewModel) {
        self._item = Bindable(item)
        self._lane = Bindable(lane)
        self.viewModel = viewModel
        
        _title = State(initialValue: item.title)
        _details = State(initialValue: item.details)
        _date = State(initialValue: item.createdAt)
        _imageData = State(initialValue: item.imageData)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // --- Polaroid Style Card ---
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width - 40,
                                       height: UIScreen.main.bounds.width - 40)
                                .clipped()
                            
                            if !title.isEmpty {
                                Text(title)
                                    .font(.headline)
                                    .padding(.horizontal)
                            }
                            if !details.isEmpty {
                                Text(details)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                        .padding(.horizontal)
                        .onTapGesture { showPhotoOptions = true }
                        
                    } else {
                        // --- Placeholder Add Photo Button ---
                        Button { showPhotoOptions = true } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue.opacity(0.8))
                                Text("Add a Photo")
                                    .font(.body)
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // --- Details Form ---
                    Form {
                        Section(header: Text("Details")) {
                            TextField("Title", text: $title)
                            TextEditor(text: $details)
                                .frame(minHeight: 100, maxHeight: 200)
                        }
                        
                        Section(header: Text("Date")) {
                            DatePicker("Date",
                                       selection: $date,
                                       displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                }
            }
            .navigationTitle(item.title.isEmpty ? "New Memory" : "Edit Memory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            
            // MARK: - Pickers & Dialogs
            .photosPicker(isPresented: $showPhotoPicker,
                          selection: $pickedImage,
                          matching: .images)
            .onChange(of: pickedImage) { newItem in
                Task {
                    guard let item = newItem else { return }
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        
                        // update EXIF date
                        if let exifDate = extractDateFromImageData(data) {
                            date = exifDate
                        }
                        
                        // crop if not square
                        if uiImage.size.width != uiImage.size.height {
                            tempImage = uiImage
                            showCropper = true
                        } else {
                            imageData = data
                        }
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { uiImage in
                    if let data = uiImage.jpegData(compressionQuality: 0.8) {
                        if uiImage.size.width != uiImage.size.height {
                            tempImage = uiImage
                            showCropper = true
                        } else {
                            imageData = data
                        }
                    }
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Choose from Library") { showPhotoPicker = true }
                if imageData != nil {
                    Button("Remove Photo", role: .destructive) { showDeleteConfirmation = true }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Remove Photo?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) { imageData = nil }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCropper) {
                if let temp = tempImage {
                    ImageCropperView(image: temp) { cropped in
                        if let data = cropped.jpegData(compressionQuality: 0.8) {
                            imageData = data
                            if let exifDate = extractDateFromImageData(data) {
                                date = exifDate
                            }
                        }
                        showCropper = false
                    }
                }
            }
        }
    }
    
    private var canSave: Bool {
        return !(title.trimmingCharacters(in: .whitespaces).isEmpty &&
                 details.trimmingCharacters(in: .whitespaces).isEmpty &&
                 imageData == nil)
    }
    
    private func saveItem() {
        guard canSave else { return }
        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        item.createdAt = date
        item.imageData = imageData
        try? modelContext.save()
    }
}

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.onCapture(uiImage)
            }
            picker.dismiss(animated: true)
        }
    }
}
