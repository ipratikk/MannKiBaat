//
//  MemoryItemEditView.swift
//  MemoriesFeature
//

import Combine
import SwiftUI
import SwiftData
import SharedModels
import PhotosUI
import UIKit

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
                            AttachmentCarousel(
                                title: "Photos",
                                attachments: $form.imageDatas,
                                addLabel: "Add Photo",
                                usePolaroidStyle: true,
                                tapStyle: .cropper
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TextField(
                                    "",
                                    text: $form.title,
                                    prompt: Text("Title (optional)").foregroundStyle(.gray),
                                    axis: .vertical
                                )
                                .focused($focusedField, equals: .title)
                                .textInputAutocapitalization(.sentences)
                                .disableAutocorrection(true)
                                .font(.title.bold())
                                .textFieldStyle(.plain)
                                .lineLimit(1)
                                
                                TextField(
                                    "",
                                    text: $form.details,
                                    prompt: Text("Description (optional)").foregroundStyle(.gray),
                                    axis: .vertical
                                )
                                .focused($focusedField, equals: .details)
                                .textInputAutocapitalization(.sentences)
                                .disableAutocorrection(false)
                                .font(.body)
                                .textFieldStyle(.plain)
                                .lineLimit(1...)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 6)
                            .padding(.horizontal)
                            
                            // Date
                            Form {
                                Section("Date") {
                                    DatePicker("Date", selection: $form.date, displayedComponents: [.date, .hourAndMinute])
                                }
                            }
                            .scrollContentBackground(.hidden)
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
                        Button(role: .destructive) { deleteItem() } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
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
    
    private func deleteItem() {
        if let existing = item {
            modelContext.delete(existing)
            try? modelContext.save()
            dismiss()
        }
    }
}
