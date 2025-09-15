//
//  MemoryItemEditView.swift
//  MannKiBaat
//

import SwiftUI
import SwiftData
import SharedModels
import PhotosUI
import ImageIO
import UniformTypeIdentifiers

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
    
    public init(item: MemoryItem,
                lane: MemoryLane,
                viewModel: MemoryViewModel) {
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
                    // --- Polaroid Card ---
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        VStack(spacing: 8) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, minHeight: 240)
                                .clipped()
                                .cornerRadius(4)
                            
                            if !title.isEmpty {
                                Text(title)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                            }
                            if !details.isEmpty {
                                Text(details)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                            
                            Text(date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 3)
                        .padding(.horizontal)
                        .onTapGesture { showPhotoOptions = true }
                    } else {
                        // Empty polaroid placeholder
                        Button {
                            showPhotoOptions = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue.opacity(0.8))
                                Text("Tap to add a photo")
                                    .font(.body)
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity, minHeight: 240)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 3)
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // --- Input Fields ---
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Title (optional)", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextEditor(text: $details)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.bottom, 8)
                        
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
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
            // MARK: - Photo Picker + Camera
            .photosPicker(isPresented: $showPhotoPicker, selection: $pickedImage, matching: .images)
            .onChange(of: pickedImage) { newItem in
                Task {
                    if let item = newItem,
                       let data = try? await item.loadTransferable(type: Data.self) {
                        imageData = data
                        if let metadataDate = extractPhotoDate(from: data) {
                            date = metadataDate
                        }
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(imageData: $imageData)
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Choose from Library") { showPhotoPicker = true }
                if imageData != nil {
                    Button("Remove Photo", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Remove Photo?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    withAnimation { imageData = nil }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private var canSave: Bool {
        !(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
          details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
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

// MARK: - Camera Picker Wrapper
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    
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
            if let uiImage = info[.originalImage] as? UIImage,
               let data = uiImage.jpegData(compressionQuality: 0.8) {
                parent.imageData = data
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Extract Metadata Date
private func extractPhotoDate(from data: Data) -> Date? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
        return nil
    }
    if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any],
       let dateStr = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateStr)
    }
    return nil
}
