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
import SwiftyCrop

// MARK: - Helpers
fileprivate func extractDateFromImageData(_ data: Data) -> Date? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
          let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
        return nil
    }
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
    let item: MemoryItem?   // nil = new item
    
    @State private var title: String
    @State private var details: String
    @State private var date: Date
    @State private var imageData: Data?
    
    // Picker + Crop
    @State private var pickedImage: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var showDeleteConfirmation = false
    @State private var presentCropper = false
    @State private var selectedUIImage: UIImage?
    
    public init(item: MemoryItem?, lane: MemoryLane, viewModel: MemoryViewModel) {
        self.item = item
        self._lane = Bindable(lane)
        self.viewModel = viewModel
        
        _title = State(initialValue: item?.title ?? "")
        _details = State(initialValue: item?.details ?? "")
        _date = State(initialValue: item?.createdAt ?? Date())
        _imageData = State(initialValue: item?.imageData)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    photoSection
                    detailsForm
                }
            }
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
            
            // MARK: - Pickers
            .photosPicker(isPresented: $showPhotoPicker, selection: $pickedImage, matching: .images)
            .onChange(of: pickedImage) { newItem in
                handlePickedImage(newItem)
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { uiImage in
                    // capture
                    selectedUIImage = uiImage
                    if let _ = uiImage.pngData() {
                        print("[MemoryItemEditView] Camera captured image")
                    }
                    // explicitly dismiss the sheet, then present cropper after small delay
                    DispatchQueue.main.async {
                        showCamera = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            presentCropper = true
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
            // Use .sheet for cropper — more forgiving here
            .sheet(isPresented: $presentCropper) {
                cropperCover()
            }
        }
    }
    
    // MARK: - Subviews
    private var photoSection: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width - 40,
                               height: UIScreen.main.bounds.width - 40)
                        .clipped()
                    
                    if !title.isEmpty {
                        Text(title).font(.headline).padding(.horizontal)
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
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.2)))
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var detailsForm: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                TextEditor(text: $details).frame(minHeight: 100, maxHeight: 200)
            }
            Section("Date") {
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }
    
    private func cropperCover() -> some View {
        Group {
            if let uiImage = selectedUIImage {
                NavigationView {
                    SwiftyCropView(
                        imageToCrop: uiImage,
                        maskShape: .square,
                        configuration: cropConfiguration,
                        onCancel: {
                            selectedUIImage = nil
                            presentCropper = false
                        },
                        onComplete: { cropped in
                            print("[MemoryItemEditView] cropped image returned: \(cropped == nil ? "nil" : "ok")")
                            handleCroppedImage(cropped)
                        }
                    )
                }
                .ignoresSafeArea()
            } else {
                // fallback so SwiftUI never receives "nothing"
                Color.clear
            }
        }
    }
    
    // MARK: - Helpers
    
    private var cropConfiguration: SwiftyCropConfiguration {
        SwiftyCropConfiguration(
            maxMagnificationScale: 4.0,
            rotateImageWithButtons: true,
            usesLiquidGlassDesign: true,
            zoomSensitivity: 6.0,
            rectAspectRatio: 1
        )
    }
    
    private var canSave: Bool {
        !(title.trimmingCharacters(in: .whitespaces).isEmpty &&
          details.trimmingCharacters(in: .whitespaces).isEmpty &&
          imageData == nil)
    }
    
    private func saveItem() {
        guard canSave else { return }
        
        if let existing = item {
            existing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.createdAt = date
            existing.imageData = imageData
        } else {
            let newItem = MemoryItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: date,
                imageData: imageData,
                parent: lane
            )
            modelContext.insert(newItem)
        }
        
        try? modelContext.save()
    }
    
    private func handlePickedImage(_ newItem: PhotosPickerItem?) {
        Task {
            guard let newItem else { return }
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                print("[MemoryItemEditView] picked image size: \(data.count) bytes")
                
                selectedUIImage = uiImage
                if let exifDate = extractDateFromImageData(data) {
                    date = exifDate
                }
                
                // Explicitly dismiss the PhotosPicker (if you're using the isPresented variant),
                // then present the cropper after a short delay.
                DispatchQueue.main.async {
                    showPhotoPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        presentCropper = true
                    }
                }
            } else {
                print("[MemoryItemEditView] failed to get image data from PhotosPickerItem")
            }
        }
    }
    
    private func handleCroppedImage(_ cropped: UIImage?) {
        if let cropped, let data = cropped.jpegData(compressionQuality: 0.8) {
            imageData = data
            if let exifDate = extractDateFromImageData(data) {
                date = exifDate
            }
        }
        // clear the selected UIImage and dismiss
        selectedUIImage = nil
        presentCropper = false
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
