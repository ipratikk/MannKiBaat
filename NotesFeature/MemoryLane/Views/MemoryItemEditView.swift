//
//  MemoryItemEditView.swift
//

import SwiftUI
import SwiftData
import SharedModels
import PhotosUI
import UIKit
import ImageIO
import SwiftyCrop
import Combine

// MARK: - Form ViewModel
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

// MARK: - Focusable Fields
fileprivate enum Field: Hashable {
    case title, details
}

@MainActor
public struct MemoryItemEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MemoryViewModel
    
    @Bindable var lane: MemoryLane
    let item: MemoryItem?
    
    @StateObject private var form: MemoryItemFormViewModel
    
    // Picker + Crop
    @State private var pickedImages: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showDeleteConfirmation = false
    @State private var presentCropper = false
    @State private var selectedUIImage: UIImage?
    @State private var editingImageIndex: Int? = nil
    @State private var showDeleteAlert = false
    @State private var selectedTab: Int = 0
    
    // Keyboard handling
    @FocusState private var focusedField: Field?
    @State private var scrollProxy: ScrollViewProxy?
    
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
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            photoSection.id(Field.title)
                            detailsForm.id(Field.details)
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                        if item == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                focusedField = .title
                            }
                        }
                    }
                    .onChange(of: focusedField) { newField in
                        withAnimation {
                            if let field = newField {
                                scrollProxy?.scrollTo(field, anchor: .center)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
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
                            form.date = Date() // always set to current date
                        }
                    }
                }
                pickedImages.removeAll()
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { uiImage in
                    if let data = uiImage.jpegData(compressionQuality: 0.8) {
                        form.imageDatas.append(data)
                        form.date = Date() // always set to current date
                    }
                }
            }
            .alert("Remove Photos?", isPresented: $showDeleteConfirmation) {
                Button("Delete All", role: .destructive) { form.imageDatas.removeAll() }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $presentCropper) { cropperCover() }
            .onAppear { syncFormWithItem() }
            .onChange(of: item?.id) { _ in syncFormWithItem() }
        }
    }
    
    // MARK: - helpers
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
    
    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(spacing: 0) {
            photoContent
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("", text: $form.title, prompt: Text("Title (optional)").foregroundStyle(.gray), axis: .vertical)
                    .focused($focusedField, equals: .title)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(true)
                    .foregroundColor(.black)
                    .font(.title.bold())
                    .textFieldStyle(.plain)
                    .tint(Color.black)
                    .lineLimit(1)
                
                TextField("", text: $form.details, prompt: Text("Description (optional)").foregroundStyle(.gray), axis: .vertical)
                    .focused($focusedField, equals: .details)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .foregroundColor(.black.opacity(0.7))
                    .font(.body)
                    .textFieldStyle(.plain)
                    .tint(Color.black.opacity(0.7))
                    .lineLimit(1...)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .globalDoneToolbar()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 6)
        .padding(.horizontal)
    }
    
    private var photoContent: some View {
        let w = UIScreen.main.bounds.width
        return Group {
            if !form.imageDatas.isEmpty {
                TabView(selection: $selectedTab) {
                    ForEach(Array(form.imageDatas.enumerated()), id: \.offset) { index, data in
                        if let ui = UIImage(data: data) {
                            MemoryImageCell(
                                uiImage: ui,
                                index: index,
                                onDelete: { form.imageDatas.remove(at: index) },
                                onEdit: {
                                    editingImageIndex = index
                                    selectedUIImage = ui
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                        presentCropper = true
                                    }
                                }
                            )
                            .tag(index)
                        }
                    }
                    AddPhotoButton(
                        onCamera: { showCamera = true },
                        onLibrary: { showPhotoPicker = true },
                        onRemoveAll: { showDeleteConfirmation = true },
                        hasPhotos: !form.imageDatas.isEmpty
                    )
                    .tag(form.imageDatas.count)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(width: w, height: w)
            } else {
                AddPhotoButton(
                    onCamera: { showCamera = true },
                    onLibrary: { showPhotoPicker = true },
                    onRemoveAll: { showDeleteConfirmation = true },
                    hasPhotos: !form.imageDatas.isEmpty
                )
                .frame(width: w, height: w)
            }
        }
    }
    
    // MARK: - Date Form
    private var detailsForm: some View {
        Form {
            Section("Date") {
                DatePicker("Date", selection: $form.date, displayedComponents: [.date, .hourAndMinute])
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
                        onComplete: { cropped in handleCroppedImage(cropped) }
                    )
                }
                .ignoresSafeArea()
            } else {
                Color.clear
            }
        }
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
            let newItem = MemoryItem(
                title: form.title.trimmingCharacters(in: .whitespacesAndNewlines),
                details: form.details.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: form.date,
                imageDatas: form.imageDatas,
                parent: lane
            )
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
            form.date = Date() // set to current date after crop
        }
        selectedUIImage = nil
        editingImageIndex = nil
        presentCropper = false
    }
}

// MARK: - Subviews
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
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(12)
        }
    }
}

// MARK: - AddPhotoButton with Inline Menu
fileprivate struct AddPhotoButton: View {
    let onCamera: () -> Void
    let onLibrary: () -> Void
    let onRemoveAll: () -> Void
    let hasPhotos: Bool
    
    var body: some View {
        Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(action: onCamera) {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            
            Button(action: onLibrary) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
            
            if hasPhotos {
                Button(role: .destructive, action: onRemoveAll) {
                    Label("Remove All Photos", systemImage: "trash")
                }
            }
        } label: {
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
