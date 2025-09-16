//
//  SpendDashboardView.swift
//  SpendsFeature
//

import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct SpendDashboardView: View {
    @Query(sort: \Spend.date, order: .reverse) private var spends: [Spend]
    
    @State private var showAddSpend = false
    
    // 🔹 Filter states
    @State private var selectedPeriod: PeriodFilter = .all
    @State private var selectedCategory: SpendCategory? = nil
    
    public init() {}
    
    public var body: some View {
        VStack {
            if filteredSpends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No spends found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Summary
                VStack(spacing: 4) {
                    Text("Total Spends")
                        .font(.headline)
                    Text(totalSpendsFormatted)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top)
                
                // Filters
                filterControls
                
                // Spends List
                List(filteredSpends) { spend in
                    SpendRow(spend: spend)
                }
            }
        }
        .navigationTitle("Spends")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSpend = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddSpend) {
            AddSpendView()
        }
    }
    
    // MARK: - Filters UI
    private var filterControls: some View {
        VStack(spacing: 12) {
            // Period Picker
            Picker("Period", selection: $selectedPeriod) {
                ForEach(PeriodFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            
            // Category Picker
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag(SpendCategory?.none)
                ForEach(uniqueCategories, id: \.self) { category in
                    Text(category.name).tag(Optional(category))
                }
            }
            .pickerStyle(.menu)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private var filteredSpends: [Spend] {
        spends.filter { spend in
            // Filter by period
            let periodMatch = selectedPeriod.matches(spend.date)
            // Filter by category
            let categoryMatch = selectedCategory == nil || spend.category == selectedCategory
            return periodMatch && categoryMatch
        }
    }
    
    private var totalSpendsFormatted: String {
        let total = filteredSpends.reduce(0.0) { sum, spend in
            sum + (spend.amount * spend.exchangeRateToINR)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: NSNumber(value: total)) ?? "₹0"
    }
    
    private var uniqueCategories: [SpendCategory] {
        Array(Set(spends.compactMap { $0.category })).sorted { $0.name < $1.name }
    }
}
