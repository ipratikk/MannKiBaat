//
// SpendAnalysisView.swift
// SpendsFeature
//

import SwiftUI
import SwiftData
import SharedModels
import Charts

@MainActor
public struct SpendAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Spend.date, order: .reverse) private var spends: [Spend]
    @StateObject private var service = SpendsService.shared
    
    @State private var selectedCategory: SpendCategory?
    @State private var selectedPeriod: PeriodFilter = .all
    @State private var selectedMonthKey: String?
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summarySection
                Divider()
                quickFilters
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
                    Button("INR") { service.currencySync.updateCurrency(to: "INR") }
                    Button("USD") { service.currencySync.updateCurrency(to: "USD") }
                } label: { Label(service.currencySync.displayCurrency, systemImage: "dollarsign.circle") }
            }
        }
        .onAppear { service.currencySync.sync() }
    }
    
    private var filteredSpends: [Spend] {
        service.filteredSpends(from: spends, category: selectedCategory, period: selectedPeriod, monthKey: selectedMonthKey)
    }
    
    private var summarySection: some View {
        VStack(spacing: 6) {
            Text("Filtered Summary").font(.headline)
            Text(service.totalSpendsFormatted(from: filteredSpends))
                .font(.largeTitle).bold()
                .foregroundColor(service.budgetColor(from: filteredSpends))
            HStack(spacing: 16) {
                Label("\(filteredSpends.count) items", systemImage: "list.bullet")
                Label("Avg/day: \(service.averagePerDayFormatted(from: filteredSpends))", systemImage: "calendar")
            }.font(.subheadline).foregroundColor(.secondary)
            if service.currencySync.budgetAmount > 0 {
                Text(service.budgetLabel(from: filteredSpends))
                    .font(.footnote)
                    .foregroundColor(service.budgetColor(from: filteredSpends))
            }
        }
        .padding(.vertical)
    }
    
    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill("All", selected: selectedCategory == nil && selectedMonthKey == nil && selectedPeriod == .all) { resetFilters() }
                ForEach(Array(Set(spends.compactMap { $0.category })).sorted { $0.name < $1.name }, id: \.self) { c in
                    filterPill(c.name, selected: selectedCategory == c) { selectedCategory = c }
                }
                ForEach(service.uniqueMonths(from: spends), id: \.self) { month in
                    filterPill(month, selected: selectedMonthKey == month) {
                        selectedPeriod = .month
                        selectedMonthKey = month
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func filterPill(_ label: String, selected: Bool, action: @escaping ()->Void) -> some View {
        Button(action: action) {
            Text(label).padding(.vertical, 6).padding(.horizontal, 12)
                .background(selected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(selected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    private func resetFilters() {
        selectedCategory = nil; selectedPeriod = .all; selectedMonthKey = nil
    }
    
    private var transactionsSection: some View {
        VStack(alignment: .leading) {
            Text("Transactions").font(.headline).padding(.bottom, 4)
            List {
                ForEach(service.groupedSpends(filteredSpends), id: \.0) { section, items in
                    Section(header: Text(section)) {
                        ForEach(items) { spend in
                            NavigationLink { EditSpendView(spend: spend) } label: {
                                SpendRow(spend: spend, section: section)
                            }
                        }
                        .onDelete { idx in for i in idx { service.deleteSpend(items[i], in: modelContext) } }
                    }
                }
            }
            .frame(height: min(CGFloat(filteredSpends.count) * 60, 400))
        }
        .padding(.horizontal)
    }
}
