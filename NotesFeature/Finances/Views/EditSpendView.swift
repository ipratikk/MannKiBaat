//
//  EditSpendView.swift
//  SpendsFeature
//

import SwiftUI
import SwiftData
import SharedModels
import PhotosUI

@MainActor
public struct EditSpendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var spend: Spend
    @Query(sort: \SpendCategory.name) private var categories: [SpendCategory]
    
    private let service = SpendsService.shared
    @State private var receiptPickerItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var showDeleteAlert = false
    
    public init(spend: Spend) {
        self._spend = Bindable(wrappedValue: spend)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()
                
                Form {
                    Section("Title & Detail") {
                        TextField("Title", text: $spend.title)
                        TextField("Detail (optional)", text: Binding(
                            get: { spend.detail ?? "" },
                            set: { spend.detail = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .lineLimit(1...)
                    }
                    
                    Section("Amount") {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                TextField("Enter amount", value: $spend.amount, format: .number)
                                    .keyboardType(.decimalPad)
                                Text(spend.currency).foregroundColor(.secondary)
                            }
                            if let preview = formattedPreview {
                                Text(preview)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section("Category") {
                        Picker("Select Category", selection: $spend.category) {
                            ForEach(categories) { c in
                                Text(c.name).tag(Optional(c))
                            }
                        }
                    }
                    
                    Section("Date") {
                        DatePicker("Transaction Date", selection: $spend.date, displayedComponents: .date)
                    }
                    
                    Section("Receipt") {
                        PhotosPicker(selection: $receiptPickerItem, matching: .images) {
                            Label("Select Receipt Photo", systemImage: "photo")
                        }
                        if let image = receiptImage {
                            Image(uiImage: image)
                                .resizable().scaledToFit().frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else if let data = spend.receiptImageData,
                                  let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFit().frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Label("Delete Spend", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden) // ✅ gradient shows
            }
            .navigationTitle("Edit Spend")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        service.saveEdits(for: spend, in: modelContext)
                        dismiss()
                    }
                    .disabled(!service.isValidInput(title: spend.title, amount: "\(spend.amount)"))
                }
            }
            .onChange(of: receiptPickerItem) { _ in
                Task {
                    if let data = try? await receiptPickerItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        receiptImage = uiImage
                        spend.receiptImageData = uiImage.jpegData(compressionQuality: 0.8)
                    }
                }
            }
            .alert("Delete Spend?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    service.deleteSpend(spend, in: modelContext)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private var formattedPreview: String? {
        spend.amount > 0
        ? CurrencyCache.format(spend.amount, currency: spend.currency)
        : nil
    }
}
