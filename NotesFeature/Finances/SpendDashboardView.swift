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
    
    // 🔹 Filters
    @State private var selectedPeriod: PeriodFilter = .all
    @State private var selectedCategory: SpendCategory? = nil
    
    // 🔹 Budget (AppStorage-friendly)
    @AppStorage("budgetAmount") private var budgetAmount: Double = 0
    @AppStorage("budgetPeriod") private var budgetPeriodRaw: String = PeriodFilter.month.rawValue
    @State private var showBudgetSheet = false
    
    // Computed wrapper for convenience
    private var budgetPeriod: PeriodFilter {
        PeriodFilter(rawValue: budgetPeriodRaw) ?? .month
    }
    
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
                
                // Budget Progress
                if budgetAmount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Budget (\(budgetPeriod.displayName))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("₹\(Int(budgetAmount))")
                                .font(.subheadline)
                                .bold()
                        }
                        
                        ProgressView(value: budgetProgress)
                            .tint(budgetProgress > 1 ? .red : .blue)
                        
                        Text("Used: \(Int(spentThisBudgetPeriod))/\(Int(budgetAmount))")
                            .font(.caption)
                            .foregroundColor(budgetProgress > 1 ? .red : .secondary)
                    }
                    .padding()
                }
                
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
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showBudgetSheet = true
                } label: {
                    Image(systemName: "chart.pie")
                }
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
        .sheet(isPresented: $showBudgetSheet) {
            BudgetSettingsView(
                budgetAmount: $budgetAmount,
                budgetPeriodRaw: $budgetPeriodRaw
            )
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
            let periodMatch = selectedPeriod.matches(spend.date)
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
    
    // Budget helpers
    private var spentThisBudgetPeriod: Double {
        spends.filter { budgetPeriod.matches($0.date) }
            .reduce(0.0) { sum, spend in sum + (spend.amount * spend.exchangeRateToINR) }
    }
    
    private var budgetProgress: Double {
        guard budgetAmount > 0 else { return 0 }
        return spentThisBudgetPeriod / budgetAmount
    }
}
