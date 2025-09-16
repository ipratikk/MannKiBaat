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
    @State private var imageDatas: [Data]    // multiple images
    
    // Picker + Crop
    @State private var pickedImages: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var showDeleteConfirmation = false
    @State private var presentCropper = false
    @State private var selectedUIImage: UIImage?
    @State private var editingImageIndex: Int? = nil
    @State private var showDeleteAlert = false
    
    public init(item: MemoryItem?, lane: MemoryLane, viewModel: MemoryViewModel) {
        self.item = item
        self._lane = Bindable(lane)
        self.viewModel = viewModel
        
        _title = State(initialValue: item?.title ?? "")
        _details = State(initialValue: item?.details ?? "")
        _date = State(initialValue: item?.createdAt ?? Date())
        _imageDatas = State(initialValue: item?.imageDatas ?? [])
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Gradient background
                GradientBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        photoSection
                        detailsForm
                    }
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
                // ✅ Delete button if editing existing item
                if item != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .alert("Delete Memory?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let existing = item {
                        modelContext.delete(existing)
                        try? modelContext.save()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This memory will be permanently deleted.")
            }
            
            // MARK: - Pickers
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $pickedImages,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: pickedImages) { newItems in
                for newItem in newItems {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let _ = UIImage(data: data) {
                            imageDatas.append(data)
                            if let exifDate = extractDateFromImageData(data),
                               imageDatas.count == 1 {
                                date = exifDate
                            }
                        }
                    }
                }
                pickedImages.removeAll()
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { uiImage in
                    if let data = uiImage.jpegData(compressionQuality: 0.8) {
                        imageDatas.append(data)
                    }
                    DispatchQueue.main.async {
                        showCamera = false
                    }
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Choose from Library") { showPhotoPicker = true }
                if !imageDatas.isEmpty {
                    Button("Remove All Photos", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Remove Photos?", isPresented: $showDeleteConfirmation) {
                Button("Delete All", role: .destructive) { imageDatas.removeAll() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $presentCropper) {
                cropperCover()
            }
        }
    }
    
    // MARK: - Polaroid Photo Section
    private var photoSection: some View {
        VStack(spacing: 0) {
            if !imageDatas.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(imageDatas.enumerated()), id: \.offset) { index, data in
                            if let ui = UIImage(data: data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 220, height: 220)
                                        .clipped()
                                        .cornerRadius(6)
                                        .onTapGesture {
                                            editingImageIndex = index
                                            selectedUIImage = ui
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                presentCropper = true
                                            }
                                        }
                                    
                                    Button {
                                        withAnimation {
                                            var arr = imageDatas
                                            arr.remove(at: index)
                                            imageDatas = arr
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .padding(6)
                                    }
                                }
                            }
                        }
                        
                        // ✅ Always show Add button
                        Button {
                            showPhotoOptions = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue.opacity(0.8))
                                Text("Add")
                                    .font(.caption)
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                            .frame(width: 100, height: 100)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 240)
            } else {
                Button { showPhotoOptions = true } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.black.opacity(0.8))
                        Text("Add a Photo")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                }
                .buttonStyle(.plain)
            }
            
            // ✅ Polaroid bottom area (Title + Description with black text)
            VStack(alignment: .leading, spacing: 8) {
                TextField("", text: $title, prompt: Text("Title (optional)").foregroundStyle(.gray), axis: .vertical)
                    .lineLimit(1...2)
                    .foregroundColor(.black)
                    .font(.title.bold())
                    .textFieldStyle(.plain)
                
                TextField("", text: $details, prompt: Text("Description (optional)").foregroundStyle(.gray), axis: .vertical)
                    .lineLimit(1...)
                    .foregroundColor(.black.opacity(0.7))
                    .font(.body)
                    .textFieldStyle(.plain)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 6)
        .padding()
    }
    
    // MARK: - Date Picker Section
    private var detailsForm: some View {
        Form {
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
                            editingImageIndex = nil
                            presentCropper = false
                        },
                        onComplete: { cropped in
                            handleCroppedImage(cropped)
                        }
                    )
                }
                .ignoresSafeArea()
            } else {
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
          imageDatas.isEmpty)
    }
    
    private func saveItem() {
        guard canSave else { return }
        
        if let existing = item {
            existing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.createdAt = date
            existing.imageDatas = imageDatas
        } else {
            let newItem = MemoryItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: date,
                imageDatas: imageDatas,
                parent: lane
            )
            modelContext.insert(newItem)
        }
        
        try? modelContext.save()
    }
    
    private func handleCroppedImage(_ cropped: UIImage?) {
        if let cropped, let data = cropped.jpegData(compressionQuality: 0.8) {
            if let index = editingImageIndex {
                guard index < imageDatas.count else { return }
                var arr = imageDatas
                arr[index] = data
                imageDatas = arr
            } else {
                imageDatas.append(data)
            }
            
            if let exifDate = extractDateFromImageData(data) {
                date = exifDate
            }
        }
        selectedUIImage = nil
        editingImageIndex = nil
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
