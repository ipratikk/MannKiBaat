//
//  SpendTrendChart.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//

import SwiftUI
import Charts
import SharedModels

public struct SpendTrendChart: View {
    let spends: [Spend]
    @Binding var selectedPeriod: PeriodFilter
    @Binding var selectedMonthKey: String?
    @StateObject private var service = SpendsService.shared
    
    public init(spends: [Spend], selectedPeriod: Binding<PeriodFilter>, selectedMonthKey: Binding<String?>) {
        self.spends = spends
        self._selectedPeriod = selectedPeriod
        self._selectedMonthKey = selectedMonthKey
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Trend (\(CurrencyCache.shared.symbol(for: service.currencySync.displayCurrency)))")
                .font(.headline).padding(.bottom, 4)
            
            let data = service.monthlyTotals(from: spends)
            if data.isEmpty {
                Text("No data available").font(.caption).foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(data, id: \.0) { item in
                        BarMark(
                            x: .value("Month", item.0),
                            y: .value("Amount", item.1)
                        )
                        .foregroundStyle(selectedMonthKey == item.0 ? .orange : .blue)
                    }
                }
                .chartYAxisLabel(position: .trailing) {
                    Text(CurrencyCache.shared.symbol(for: service.currencySync.displayCurrency))
                        .font(.caption).foregroundColor(.secondary)
                }
                .frame(height: 220)
            }
        }
        .padding(.horizontal)
    }
}
