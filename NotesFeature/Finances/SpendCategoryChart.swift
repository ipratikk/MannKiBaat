//
//  SpendCategoryChart.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 17/09/25.
//

import SwiftUI
import Charts
import SharedModels

public struct SpendCategoryChart: View {
    let spends: [Spend]
    @Binding var selectedCategory: SpendCategory?
    @StateObject private var service = SpendsService.shared
    
    public init(spends: [Spend], selectedCategory: Binding<SpendCategory?>) {
        self.spends = spends
        self._selectedCategory = selectedCategory
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("Category Breakdown (\(CurrencyCache.shared.symbol(for: service.currencySync.displayCurrency)))")
                .font(.headline).padding(.bottom, 4)
            
            let data = service.categoryTotals(from: spends)
            if data.isEmpty {
                Text("No data available").font(.caption).foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(data, id: \.0?.id) { pair in
                        SectorMark(
                            angle: .value("Amount", pair.1),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", pair.0?.name ?? "Others"))
                    }
                }
                .chartLegend(.visible)
                .frame(height: 220)
            }
        }
        .padding(.horizontal)
    }
}
