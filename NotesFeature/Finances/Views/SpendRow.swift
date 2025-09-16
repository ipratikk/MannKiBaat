//
// SpendRow.swift
// SpendsFeature
//

import SwiftUI
import SharedModels

@MainActor
public struct SpendRow: View {
    let spend: Spend
    let section: String
    
    @StateObject private var currencySync = CurrencySyncService.shared
    
    public init(spend: Spend, section: String) {
        self.spend = spend
        self.section = section
    }
    
    public var body: some View {
        HStack {
            // Category icon
            Image(systemName: spend.category?.icon ?? "tag")
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(spend.title)
                    .font(.headline)
                if let detail = spend.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(DateDisplayFormatter.formattedRowDate(spend.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Formatted amount in original currency
            Text(formattedAmount)
                .font(.subheadline).bold()
        }
    }
    
    private var formattedAmount: String {
        CurrencyCache.format(spend.amount, currency: spend.currency)
    }
}
