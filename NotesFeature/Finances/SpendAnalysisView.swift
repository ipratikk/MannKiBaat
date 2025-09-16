//
//  SpendAnalysisView.swift
//  SpendsFeature
//

import SwiftUI
import SwiftData
import SharedModels
import Charts

@MainActor
public struct SpendAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Spend.date, order: .reverse) private var spends: [Spend]
    
    @AppStorage("displayCurrency") private var displayCurrency: String = "INR"
    @AppStorage("budgetCurrency") private var budgetCurrency: String = "INR"
    @AppStorage("budgetAmount") private var budgetAmount: Double = 0
    @AppStorage("budgetPeriod") private var budgetPeriodRaw: String = PeriodFilter.month.rawValue
    
    @State private var selectedCategory: SpendCategory?
    @State private var selectedPeriod: PeriodFilter = .all
    @State private var selectedMonthKey: String?
    
    private var budgetPeriod: PeriodFilter {
        PeriodFilter(rawValue: budgetPeriodRaw) ?? .month
    }
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summarySection
                Divider()
                quickFilterPills.padding(.horizontal)
                Divider()
                SpendCategoryChart(spends: filteredSpends, selectedCategory: $selectedCategory)
                Divider()
                SpendTrendChart(spends: filteredSpends, selectedPeriod: $selectedPeriod, selectedMonthKey: $selectedMonthKey)
                Divider()
                transactionsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Analysis")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("INR") { displayCurrency = "INR" }
                    Button("USD") { displayCurrency = "USD" }
                } label: {
                    Label(displayCurrency, systemImage: "dollarsign.circle")
                }
            }
        }
    }
    
    // MARK: - Summary
    
    private var summarySection: some View {
        VStack(spacing: 6) {
            Text("Filtered Summary").font(.headline)
            
            Text(totalSpendsFormatted)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(budgetColor)
            
            HStack(spacing: 16) {
                Label("\(filteredSpends.count) items", systemImage: "list.bullet")
                Label("Avg/day: \(averagePerDayFormatted)", systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if budgetAmount > 0 {
                Text("Budget: \(CurrencyCache.format(convertedBudgetAmount, currency: displayCurrency)) (\(budgetPeriod.displayName))")
                    .font(.footnote)
                    .foregroundColor(budgetColor)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Transactions
    
    private var transactionsSection: some View {
        VStack(alignment: .leading) {
            Text("Transactions").font(.headline).padding(.bottom, 4)
            
            List {
                ForEach(filteredSpends) { spend in
                    NavigationLink {
                        EditSpendView(spend: spend)
                    } label: {
                        SpendRow(spend: spend)
                    }
                }
                .onDelete(perform: deleteSpends)
            }
            .frame(height: min(CGFloat(filteredSpends.count) * 60, 400)) // compact list
        }
        .padding(.horizontal)
    }
    
    // MARK: - Filters
    
    private var quickFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All
                filterPill(
                    label: "All",
                    isSelected: selectedCategory == nil && selectedMonthKey == nil && selectedPeriod == .all
                ) { resetFilters() }
                
                // Categories
                let sortedCategories = Array(Set(spends.compactMap { $0.category }))
                    .sorted { $0.name < $1.name }
                ForEach(sortedCategories.prefix(2), id: \.self) { category in
                    filterPill(
                        label: category.name,
                        isSelected: selectedCategory == category
                    ) { selectedCategory = category }
                }
                
                // Latest month
                if let latestMonth = uniqueMonths.sorted().last {
                    filterPill(
                        label: latestMonth,
                        isSelected: selectedMonthKey == latestMonth
                    ) {
                        selectedPeriod = .month
                        selectedMonthKey = latestMonth
                    }
                }
                
                // More menu
                Menu {
                    Section("Categories") {
                        ForEach(sortedCategories, id: \.self) { category in
                            Button(category.name) { selectedCategory = category }
                        }
                    }
                    Section("Months") {
                        Button("All Months") {
                            selectedPeriod = .all
                            selectedMonthKey = nil
                        }
                        ForEach(uniqueMonths, id: \.self) { month in
                            Button(month) {
                                selectedPeriod = .month
                                selectedMonthKey = month
                            }
                        }
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func filterPill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    private var uniqueMonths: [String] {
        let f = DateFormatter(); f.dateFormat = "MMM yy"
        let keys = spends.map { f.string(from: $0.date) }
        return Array(Set(keys)).sorted()
    }
    
    private func resetFilters() {
        selectedCategory = nil
        selectedPeriod = .all
        selectedMonthKey = nil
    }
    
    // MARK: - Helpers
    
    private var convertedBudgetAmount: Double {
        let budgetInINR: Double
        if budgetCurrency == "USD" {
            budgetInINR = budgetAmount * CurrencyCache.shared.usdToInrRate
        } else {
            budgetInINR = budgetAmount
        }
        return CurrencyCache.shared.convertBudget(budgetInINR, to: displayCurrency)
    }
    
    private var totalSpends: Double {
        let totalINR = filteredSpends.reduce(0.0) { $0 + ($1.amount * $1.exchangeRateToINR) }
        return CurrencyCache.shared.convertFromINR(totalINR, to: displayCurrency)
    }
    
    private var totalSpendsFormatted: String {
        CurrencyCache.format(totalSpends, currency: displayCurrency)
    }
    
    private var averagePerDayFormatted: String {
        guard let minDate = filteredSpends.map({ $0.date }).min(),
              let maxDate = filteredSpends.map({ $0.date }).max() else {
            return CurrencyCache.format(0, currency: displayCurrency)
        }
        let days = max(Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0, 1)
        let avgINR = filteredSpends.reduce(0.0) { $0 + ($1.amount * $1.exchangeRateToINR) } / Double(days)
        let avg = CurrencyCache.shared.convertFromINR(avgINR, to: displayCurrency)
        return CurrencyCache.format(avg, currency: displayCurrency)
    }
    
    private var budgetColor: Color {
        guard convertedBudgetAmount > 0 else { return .primary }
        return totalSpends > convertedBudgetAmount ? .red : .green
    }
    
    private var filteredSpends: [Spend] {
        spends.filter { spend in
            var match = true
            if let selectedCategory {
                match = match && spend.category == selectedCategory
            }
            if selectedPeriod != .all {
                match = match && selectedPeriod.matches(spend.date)
            }
            if let key = selectedMonthKey {
                let f = DateFormatter(); f.dateFormat = "MMM yy"
                let monthKey = f.string(from: spend.date)
                match = match && (monthKey == key)
            }
            return match
        }
    }
    
    private func deleteSpends(at offsets: IndexSet) {
        for index in offsets {
            let spend = filteredSpends[index]
            modelContext.delete(spend)
        }
        try? modelContext.save()
    }
}
