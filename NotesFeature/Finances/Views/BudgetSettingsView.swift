//
// BudgetSettingsView.swift
// SpendsFeature
//

import SwiftUI
import SharedModels

public struct BudgetSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var currencySync = CurrencySyncService.shared
    
    @State private var inputAmount: String = ""
    @State private var tempCurrency: String = "INR"
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section("Budget Amount") {
                    HStack {
                        TextField("Enter amount", text: $inputAmount)
                            .keyboardType(.decimalPad)
                        
                        Picker("Currency", selection: $tempCurrency) {
                            Text("INR").tag("INR")
                            Text("USD").tag("USD")
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 120)
                        .onChange(of: tempCurrency) { newValue in
                            convertAmountIfNeeded(from: currencySync.budgetCurrency, to: newValue)
                            currencySync.updateCurrency(to: newValue)
                        }
                    }
                }
                
                Section("Budget Period") {
                    Picker("Period", selection: $currencySync.budgetPeriodRaw) {
                        ForEach([PeriodFilter.month, .quarter, .year], id: \.self) { filter in
                            Text(filter.displayName).tag(filter.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Budget Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        currencySync.budgetAmount = Double(inputAmount) ?? 0
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempCurrency = currencySync.budgetCurrency
                inputAmount = currencySync.budgetAmount > 0 ? "\(Int(currencySync.budgetAmount))" : ""
            }
        }
    }
    
    private func convertAmountIfNeeded(from oldCurrency: String, to newCurrency: String) {
        guard let value = Double(inputAmount), value > 0 else { return }
        if oldCurrency == "INR", newCurrency == "USD" {
            let converted = value / CurrencyCache.shared.usdToInrRate
            inputAmount = String(format: "%.0f", converted)
        } else if oldCurrency == "USD", newCurrency == "INR" {
            let converted = value * CurrencyCache.shared.usdToInrRate
            inputAmount = String(format: "%.0f", converted)
        }
    }
}
