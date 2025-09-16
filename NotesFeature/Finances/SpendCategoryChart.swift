//
//  SpendCategoryChart.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//

import SwiftUI
import Charts
import SharedModels

struct SpendCategoryChart: View {
    let spends: [Spend]
    @Binding var selectedCategory: SpendCategory?
    
    private var categoryTotals: [(SpendCategory?, Double)] {
        var totals: [SpendCategory?: Double] = [:]
        for spend in spends {
            let amountINR = spend.amount * spend.exchangeRateToINR
            totals[spend.category, default: 0] += amountINR
        }
        return totals.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Category Breakdown")
                .font(.headline)
                .padding(.bottom, 4)
            
            if categoryTotals.isEmpty {
                Text("No data available").font(.caption).foregroundColor(.secondary)
            } else {
                Chart(categoryTotals, id: \.0?.id) { item in
                    SectorMark(
                        angle: .value("Amount", item.1),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Category", item.0?.name ?? "Others"))
                }
                .chartLegend(.visible)
            }
        }
    }
}
