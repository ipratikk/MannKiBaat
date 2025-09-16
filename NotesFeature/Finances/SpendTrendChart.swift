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
    
    private var monthlyTotals: [(String, Double)] {
        let f = DateFormatter(); f.dateFormat = "MMM yy"
        var totals: [String: Double] = [:]
        for spend in spends {
            let key = f.string(from: spend.date)
            totals[key, default: 0] += (spend.amount * spend.exchangeRateToINR)
        }
        return totals.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Trend")
                .font(.headline)
                .padding(.bottom, 4)
            
            if monthlyTotals.isEmpty {
                Text("No data available").font(.caption).foregroundColor(.secondary)
            } else {
                Chart(monthlyTotals, id: \.0) { item in
                    BarMark(
                        x: .value("Month", item.0),
                        y: .value("Amount", item.1)
                    )
                    .foregroundStyle(selectedMonthKey == item.0 ? .orange : .blue)
                }
            }
        }
    }
}
