//
//  BudgetSettingsView.swift
//  SpendsFeature
//

import SwiftUI

struct BudgetSettingsView: View {
    @Binding var budgetAmount: Double
    @Binding var budgetPeriodRaw: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputAmount: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Amount") {
                    TextField("Enter amount", text: $inputAmount)
                        .keyboardType(.decimalPad)
                }
                
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
                inputAmount = budgetAmount > 0 ? "\(Int(budgetAmount))" : ""
            }
        }
    }
}
