//
//  EditSpendView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//

import SwiftUI
import SwiftData
import SharedModels
import PhotosUI

@MainActor
public struct EditSpendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var spend: Spend  // ✅ directly bound to existing spend
    
    @Query(sort: \SpendCategory.name) private var categories: [SpendCategory]
    
    @State private var receiptPickerItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    @State private var showDeleteAlert = false
    
    public init(spend: Spend) {
        self._spend = Bindable(wrappedValue: spend)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Enter amount", value: $spend.amount, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $spend.currency) {
                        Text("INR").tag("INR")
                        Text("USD").tag("USD")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Category") {
                    Picker("Select Category", selection: $spend.category) {
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category))
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
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 4)
                    } else if let data = spend.receiptImageData,
                              let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 4)
                    }
                }
                
                // 🔴 Delete button section
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Spend", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Spend")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
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
                    deleteSpend()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private func saveChanges() {
        try? modelContext.save()
    }
    
    private func deleteSpend() {
        modelContext.delete(spend)
        try? modelContext.save()
        dismiss()
    }
}
