//
//  BudgetSettingsView.swift
//  SpendsFeature
//

import SwiftUI
import SharedModels

struct BudgetSettingsView: View {
    @Binding var budgetAmount: Double
    @Binding var budgetCurrency: String
    @Binding var budgetPeriodRaw: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputAmount: String = ""
    @State private var tempCurrency: String = "INR"
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Budget Amount + Currency
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
                            convertAmountIfNeeded(from: budgetCurrency, to: newValue)
                            budgetCurrency = newValue
                        }
                    }
                }
                
                // MARK: Budget Period
                Section("Budget Period") {
                    Picker("Period", selection: $budgetPeriodRaw) {
                        ForEach([PeriodFilter.month, .quarter, .year], id: \.self) { filter in
                            Text(filter.displayName).tag(filter.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Budget Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        budgetAmount = Double(inputAmount) ?? 0
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempCurrency = budgetCurrency
                if budgetAmount > 0 {
                    inputAmount = "\(Int(budgetAmount))"
                } else {
                    inputAmount = ""
                }
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
