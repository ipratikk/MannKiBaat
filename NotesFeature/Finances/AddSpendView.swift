//
//  AddSpendView.swift
//  SpendsFeature
//

import SwiftUI
import SwiftData
import SharedModels
import PhotosUI

@MainActor
public struct AddSpendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \SpendCategory.name) private var categories: [SpendCategory]
    
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var amount: String = ""
    @State private var currency: String = "INR"
    @State private var date: Date = Date()
    @State private var selectedCategory: SpendCategory?
    @State private var receiptPickerItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Title & Detail") {
                    TextField("Title", text: $title)
                    TextField("Detail (optional)", text: $detail, axis: .vertical)
                        .lineLimit(1...)
                }
                
                Section("Amount") {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Currency", selection: $currency) {
                        Text("INR").tag("INR")
                        Text("USD").tag("USD")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Category") {
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category))
                        }
                    }
                }
                
                Section("Date") {
                    DatePicker("Transaction Date", selection: $date, displayedComponents: .date)
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
                    }
                }
            }
            .navigationTitle("Add Spend")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveSpend() }
                        .disabled(!isValidInput) // ✅ disable if invalid
                }
            }
            .onChange(of: receiptPickerItem) { _ in
                Task {
                    if let data = try? await receiptPickerItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        receiptImage = uiImage
                    }
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(amount) ?? 0) > 0
    }
    
    private func saveSpend() {
        Task {
            guard isValidInput else { return }
            
            // ✅ Fallback to "Others" if no category
            let category = selectedCategory ?? CategoryService.fetchOrCreateOthersCategory(in: modelContext)
            
            let rate = await CurrencyService.fetchExchangeRate(from: currency, date: date)
            
            let spend = Spend(
                title: title,
                detail: detail.isEmpty ? nil : detail,
                amount: Double(amount) ?? 0,
                currency: currency,
                date: date,
                category: category,
                receiptImageData: receiptImage?.jpegData(compressionQuality: 0.8),
                exchangeRateToINR: rate
            )
            
            modelContext.insert(spend)
            try? modelContext.save()
            dismiss()
        }
    }
}
