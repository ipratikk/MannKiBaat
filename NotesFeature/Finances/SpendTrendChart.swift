//
//  SpendTrendChart.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//

import SwiftUI
import Charts
import SharedModels

struct SpendTrendChart: View {
    let spends: [Spend]
    @Binding var selectedPeriod: PeriodFilter
    @Binding var selectedMonthKey: String?
    @AppStorage("displayCurrency") private var displayCurrency: String = "INR"
    
    private var monthlyTotals: [(String, Double)] {
        let f = DateFormatter(); f.dateFormat = "MMM yy"
        var totals: [String: Double] = [:]
        for spend in spends {
            let amountINR = spend.amount * spend.exchangeRateToINR
            let converted = CurrencyCache.shared.convertFromINR(amountINR, to: displayCurrency)
            totals[f.string(from: spend.date), default: 0] += converted
        }
        return totals.sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Trend (\(CurrencyCache.shared.symbol(for: displayCurrency)))")
                .font(.headline)
                .padding(.bottom, 4)
            
            if monthlyTotals.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Chart(monthlyTotals, id: \.0) { item in
                    BarMark(
                        x: .value("Month", item.0),
                        y: .value("Amount", item.1)
                    )
                    .foregroundStyle(selectedMonthKey == item.0 ? .orange : .blue)
                }
                .chartYAxisLabel(position: .trailing) {
                    Text(CurrencyCache.shared.symbol(for: displayCurrency))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
