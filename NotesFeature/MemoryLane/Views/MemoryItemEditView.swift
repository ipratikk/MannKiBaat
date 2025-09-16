//
// MemoryItemEditView.swift
//

import SwiftUI
import SwiftData
import SharedModels
import PhotosUI
import UIKit
import ImageIO
import SwiftyCrop
import Combine

// helpers
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

// Form view-model (keeps UI state stable and easy to reset)
final class MemoryItemFormViewModel: ObservableObject {
    @Published var title: String
    @Published var details: String
    @Published var date: Date
    @Published var imageDatas: [Data]
    
    init(item: MemoryItem?) {
        self.title = item?.title ?? ""
        self.details = item?.details ?? ""
        self.date = item?.createdAt ?? Date()
        self.imageDatas = item?.imageDatas ?? []
    }
}

@MainActor
public struct MemoryItemEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MemoryViewModel
    
    @Bindable var lane: MemoryLane
    let item: MemoryItem?    // nil => new
    
    @StateObject private var form: MemoryItemFormViewModel
    
    // pickers + crop
    @State private var pickedImages: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var showDeleteConfirmation = false
    @State private var presentCropper = false
    @State private var selectedUIImage: UIImage?
    @State private var editingImageIndex: Int? = nil
    @State private var showDeleteAlert = false
    @State private var selectedTab: Int = 0
    
    public init(item: MemoryItem?, lane: MemoryLane, viewModel: MemoryViewModel) {
        self.item = item
        self._lane = Bindable(lane)
        self.viewModel = viewModel
        _form = StateObject(wrappedValue: MemoryItemFormViewModel(item: item))
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView().ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        photoSection
                        detailsForm
                    }
                }
            }
            .onAppear { syncFormWithItem() }        // keep safe: guarantee data sync on appear
            .onChange(of: item?.id) { _ in syncFormWithItem() } // if item identity somehow changes
            .navigationTitle(item == nil ? "New Memory" : "Edit Memory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveItem(); dismiss() }
                        .disabled(!canSave)
                }
                if item != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) { showDeleteAlert = true } label: {
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
            // Photos picker (multiple)
            .photosPicker(isPresented: $showPhotoPicker, selection: $pickedImages, matching: .images)
            .onChange(of: pickedImages) { newItems in
                for newItem in newItems {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           UIImage(data: data) != nil {
                            form.imageDatas.append(data)
                            if let exifDate = extractDateFromImageData(data), form.imageDatas.count == 1 {
                                form.date = exifDate
                            }
                        }
                    }
                }
                pickedImages.removeAll()
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { uiImage in
                    if let data = uiImage.jpegData(compressionQuality: 0.8) {
                        form.imageDatas.append(data)
                    }
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Choose from Library") { showPhotoPicker = true }
                if !form.imageDatas.isEmpty {
                    Button("Remove All Photos", role: .destructive) { showDeleteConfirmation = true }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Remove Photos?", isPresented: $showDeleteConfirmation) {
                Button("Delete All", role: .destructive) { form.imageDatas.removeAll() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $presentCropper) {
                cropperCover()
            }
        }
    }
    
    // MARK: helpers
    private func syncFormWithItem() {
        if let existing = item {
            form.title = existing.title
            form.details = existing.details
            form.date = existing.createdAt
            form.imageDatas = existing.imageDatas
        } else {
            form.title = ""
            form.details = ""
            form.date = Date()
            form.imageDatas = []
        }
    }
    
    private var photoSection: some View {
        VStack(spacing: 0) {
            photoContent
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("", text: $form.title, prompt: Text("Title (optional)").foregroundStyle(.gray), axis: .vertical)
                    .foregroundColor(.black)
                    .font(.title.bold())
                    .textFieldStyle(.plain)
                    .lineLimit(1...2)
                
                TextField("", text: $form.details, prompt: Text("Description (optional)").foregroundStyle(.gray), axis: .vertical)
                    .foregroundColor(.black.opacity(0.7))
                    .font(.body)
                    .textFieldStyle(.plain)
                    .lineLimit(1...)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 6)
        .padding(.horizontal)
    }
    
    // return any view to unify branch types
    private var photoContent: AnyView {
        let w = UIScreen.main.bounds.width
        if !form.imageDatas.isEmpty {
            return AnyView(
                TabView(selection: $selectedTab) {
                    ForEach(Array(form.imageDatas.enumerated()), id: \.offset) { index, data in
                        if let ui = UIImage(data: data) {
                            MemoryImageCell(uiImage: ui,
                                            index: index,
                                            onDelete: { form.imageDatas.remove(at: index) },
                                            onEdit: {
                                editingImageIndex = index
                                selectedUIImage = ui
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    presentCropper = true
                                }
                            })
                            .tag(index)
                        }
                    }
                    AddPhotoButton { showPhotoOptions = true }
                        .tag(form.imageDatas.count)
                }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(width: w, height: w)
            )
        } else {
            return AnyView(
                AddPhotoButton { showPhotoOptions = true }
                    .frame(width: w, height: w)
            )
        }
    }
    
    private var detailsForm: some View {
        Form {
            Section("Date") {
                DatePicker("Date", selection: $form.date, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }
    
    private func cropperCover() -> some View {
        if let uiImage = selectedUIImage {
            return AnyView(
                NavigationView {
                    SwiftyCropView(
                        imageToCrop: uiImage,
                        maskShape: .square,
                        configuration: cropConfiguration,
                        onCancel: {
                            selectedUIImage = nil
                            editingImageIndex = nil
                            presentCropper = false
                        }, onComplete: { cropped in
                            handleCroppedImage(cropped)
                        })
                }
                    .ignoresSafeArea()
            )
        }
        return AnyView(Color.clear)
    }
    
    private var cropConfiguration: SwiftyCropConfiguration {
        SwiftyCropConfiguration(maxMagnificationScale: 4.0,
                                rotateImageWithButtons: true,
                                usesLiquidGlassDesign: true,
                                zoomSensitivity: 6.0,
                                rectAspectRatio: 1)
    }
    
    private var canSave: Bool {
        !(form.title.trimmingCharacters(in: .whitespaces).isEmpty &&
          form.details.trimmingCharacters(in: .whitespaces).isEmpty &&
          form.imageDatas.isEmpty)
    }
    
    private func saveItem() {
        guard canSave else { return }
        if let existing = item {
            existing.title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.details = form.details.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.createdAt = form.date
            existing.imageDatas = form.imageDatas
        } else {
            let newItem = MemoryItem(title: form.title.trimmingCharacters(in: .whitespacesAndNewlines),
                                     details: form.details.trimmingCharacters(in: .whitespacesAndNewlines),
                                     createdAt: form.date,
                                     imageDatas: form.imageDatas,
                                     parent: lane)
            modelContext.insert(newItem)
        }
        try? modelContext.save()
    }
    
    private func handleCroppedImage(_ cropped: UIImage?) {
        if let cropped, let data = cropped.jpegData(compressionQuality: 0.8) {
            if let index = editingImageIndex, index < form.imageDatas.count {
                form.imageDatas[index] = data
            } else {
                form.imageDatas.append(data)
            }
            if let exifDate = extractDateFromImageData(data) {
                form.date = exifDate
            }
        }
        selectedUIImage = nil
        editingImageIndex = nil
        presentCropper = false
    }
}

// subviews
fileprivate struct MemoryImageCell: View {
    let uiImage: UIImage
    let index: Int
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                .clipped()
                .onTapGesture { onEdit() }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(12) // keep the X inside the image bounds
        }
    }
}

fileprivate struct AddPhotoButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                Text("Add Photo")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// Camera picker
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
