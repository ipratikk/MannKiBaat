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
    
    @State private var selectedCategory: SpendCategory? = nil
    @State private var selectedPeriod: PeriodFilter = .all
    @State private var selectedMonthKey: String? = nil
    
    @AppStorage("budgetAmount") private var budgetAmount: Double = 0
    @AppStorage("budgetPeriod") private var budgetPeriodRaw: String = PeriodFilter.month.rawValue
    @AppStorage("displayCurrency") private var displayCurrency: String = "INR"
    
    private var budgetPeriod: PeriodFilter {
        PeriodFilter(rawValue: budgetPeriodRaw) ?? .month
    }
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if spends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No spend data available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    summarySection
                    quickFilterPills
                        .padding(.horizontal)
                    
                    SpendCategoryChart(spends: spends, selectedCategory: $selectedCategory)
                        .frame(height: 250)
                        .padding(.horizontal)
                    
                    SpendTrendChart(spends: spends,
                                    selectedPeriod: $selectedPeriod,
                                    selectedMonthKey: $selectedMonthKey)
                    .frame(height: 250)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transactions")
                            .font(.headline)
                            .padding(.horizontal)
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
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analysis")
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
        .animation(.easeInOut(duration: 0.3), value: selectedPeriod)
        .animation(.easeInOut(duration: 0.3), value: selectedMonthKey)
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
            .font(.subheadline).foregroundColor(.secondary)
            
            if budgetAmount > 0 {
                Text("Budget: ₹\(Int(budgetAmount)) (\(budgetPeriod.displayName))")
                    .font(.footnote)
                    .foregroundColor(budgetColor)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Quick Filters (Collapsible)
    private var quickFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Always "All"
                filterPill(
                    label: "All",
                    isSelected: selectedCategory == nil && selectedMonthKey == nil && selectedPeriod == .all
                ) { resetFilters() }
                
                // Show 2 categories inline
                let sortedCategories = Array(Set(spends.compactMap { $0.category }))
                    .sorted { $0.name < $1.name }
                ForEach(sortedCategories.prefix(2), id: \.self) { category in
                    filterPill(
                        label: category.name,
                        isSelected: selectedCategory == category
                    ) { selectedCategory = category }
                }
                
                // Latest month inline
                if let latestMonth = uniqueMonths.sorted().last {
                    filterPill(
                        label: latestMonth,
                        isSelected: selectedMonthKey == latestMonth
                    ) {
                        selectedPeriod = .month
                        selectedMonthKey = latestMonth
                    }
                }
                
                // Collapsible menu
                Menu {
                    Section("Categories") {
                        ForEach(sortedCategories, id: \.self) { category in
                            Button(category.name) { selectedCategory = category }
                        }
                    }
                    Section("Months") {
                        Button("All Months") { selectedPeriod = .all; selectedMonthKey = nil }
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
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func deleteSpends(at offsets: IndexSet) {
        for index in offsets {
            let spend = filteredSpends[index]
            modelContext.delete(spend)
        }
        try? modelContext.save()
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
    
    // MARK: - Helpers
    private var filteredSpends: [Spend] {
        spends.filter { spend in
            let periodMatch = selectedPeriod.matches(spend.date)
            let monthMatch: Bool = {
                guard selectedPeriod == .month, let key = selectedMonthKey else { return true }
                let f = DateFormatter(); f.dateFormat = "MMM yy"
                return f.string(from: spend.date) == key
            }()
            let categoryMatch = selectedCategory == nil || spend.category == selectedCategory
            return periodMatch && monthMatch && categoryMatch
        }
    }
    
    private var totalSpends: Double {
        filteredSpends.reduce(0.0) { $0 + ($1.amount * $1.exchangeRateToINR) }
    }
    
    private var totalSpendsFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        return f.string(from: NSNumber(value: totalSpends)) ?? "₹0"
    }
    
    private var averagePerDayFormatted: String {
        guard let minDate = filteredSpends.map({ $0.date }).min(),
              let maxDate = filteredSpends.map({ $0.date }).max() else { return "₹0" }
        let days = max(Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0, 1)
        let avg = totalSpends / Double(days)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        return f.string(from: NSNumber(value: avg)) ?? "₹0"
    }
    
    private var budgetColor: Color {
        guard budgetAmount > 0 else { return .primary }
        return totalSpends > budgetAmount ? .red : .green
    }
    
    private func resetFilters() {
        selectedPeriod = .all
        selectedCategory = nil
        selectedMonthKey = nil
    }
}
