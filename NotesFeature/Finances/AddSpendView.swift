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
    
    @State private var amount: String = ""
    @State private var currency: String = "INR"
    @State private var selectedCategory: SpendCategory?
    @State private var date: Date = Date()
    
    // Receipt handling
    @State private var receiptPickerItem: PhotosPickerItem?
    @State private var receiptImage: UIImage?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
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
                    PhotosPicker(
                        selection: $receiptPickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Select Receipt Photo", systemImage: "photo")
                    }
                    
                    if let image = receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.top, 4)
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
                        .disabled(amount.isEmpty || selectedCategory == nil)
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
    
    // MARK: - Save Logic
    private func saveSpend() {
        Task {
            let rate = await fetchExchangeRate(for: currency, on: date)
            
            let spend = Spend(
                amount: Double(amount) ?? 0,
                currency: currency,
                date: date,
                category: selectedCategory,
                receiptImageData: receiptImage?.jpegData(compressionQuality: 0.8),
                exchangeRateToINR: rate
            )
            
            modelContext.insert(spend)
            try? modelContext.save()
            dismiss()
        }
    }
}
