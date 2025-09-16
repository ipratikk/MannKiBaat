//
//  SpendDashboardView.swift
//  SpendsFeature
//

import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct SpendDashboardView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Spend.date, order: .reverse) private var spends: [Spend]
    
    @State private var showAddSpend = false
    @State private var showBudgetSheet = false
    
    @AppStorage("budgetAmount") private var budgetAmount: Double = 0
    @AppStorage("budgetCurrency") private var budgetCurrency: String = "INR"
    @AppStorage("budgetPeriod") private var budgetPeriodRaw: String = PeriodFilter.month.rawValue
    @AppStorage("displayCurrency") private var displayCurrency: String = "INR"
    
    private var budgetPeriod: PeriodFilter {
        PeriodFilter(rawValue: budgetPeriodRaw) ?? .month
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            if spends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No spends yet")
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
                    budgetSection
                }
                
                List {
                    ForEach(spends) { spend in
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
        .navigationTitle("Spends")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    SpendAnalysisView()
                } label: {
                    Image(systemName: "chart.bar")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showBudgetSheet = true } label: {
                    Image(systemName: "chart.pie")
                }
                Button { showAddSpend = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddSpend) { AddSpendView() }
        .sheet(isPresented: $showBudgetSheet) {
            BudgetSettingsView(
                budgetAmount: $budgetAmount,
                budgetCurrency: $budgetCurrency,
                budgetPeriodRaw: $budgetPeriodRaw
            )
        }
    }
    
    // MARK: - Helpers
    
    private var totalSpendsFormatted: String {
        let totalINR = spends.reduce(0.0) { $0 + ($1.amount * $1.exchangeRateToINR) }
        let converted = CurrencyCache.shared.convertFromINR(totalINR, to: displayCurrency)
        return CurrencyCache.format(converted, currency: displayCurrency)
    }
    
    private var convertedBudgetAmount: Double {
        let budgetInINR: Double
        if budgetCurrency == "USD" {
            budgetInINR = budgetAmount * CurrencyCache.shared.usdToInrRate
        } else {
            budgetInINR = budgetAmount
        }
        return CurrencyCache.shared.convertBudget(budgetInINR, to: displayCurrency)
    }
    
    private var spentThisBudgetPeriod: Double {
        let totalINR = spends.filter { budgetPeriod.matches($0.date) }
            .reduce(0.0) { $0 + ($1.amount * $1.exchangeRateToINR) }
        return CurrencyCache.shared.convertFromINR(totalINR, to: displayCurrency)
    }
    
    private var budgetProgress: Double {
        guard convertedBudgetAmount > 0 else { return 0 }
        return spentThisBudgetPeriod / convertedBudgetAmount
    }
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Budget (\(budgetPeriod.displayName))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyCache.format(convertedBudgetAmount, currency: displayCurrency))
                    .font(.subheadline).bold()
            }
            ProgressView(value: budgetProgress)
                .tint(budgetProgress > 1 ? .red : .blue)
            Text("Used: \(CurrencyCache.format(spentThisBudgetPeriod, currency: displayCurrency)) / \(CurrencyCache.format(convertedBudgetAmount, currency: displayCurrency))")
                .font(.caption)
                .foregroundColor(budgetProgress > 1 ? .red : .secondary)
        }
        .padding()
    }
    
    private func deleteSpends(at offsets: IndexSet) {
        for index in offsets {
            let spend = spends[index]
            modelContext.delete(spend)
        }
        try? modelContext.save()
    }
}
