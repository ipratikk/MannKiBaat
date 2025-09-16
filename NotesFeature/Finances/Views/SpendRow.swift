//
//  SpendRow.swift
//  SpendsFeature
//

import SwiftUI
import SharedModels

public struct SpendRow: View {
    let spend: Spend
    let section: String?
    
    public init(spend: Spend, section: String? = nil) {
        self.spend = spend
        self.section = section
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Label(spend.title, systemImage: spend.category?.icon ?? "tag")
                    .font(.headline)
                Text(rowSubtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(originalAmount)
                .fontWeight(.medium)
        }
        .padding(.vertical, 6)
    }
    
    private var rowSubtitle: String {
        if let sec = section {
            if sec == "Today" || sec == "Yesterday" {
                return spend.date.timeString()
            } else {
                return DateDisplayFormatter.formattedRowDate(spend.date)
            }
        } else {
            return DateDisplayFormatter.formattedRowDate(spend.date)
        }
    }
    
    private var originalAmount: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = spend.currency
        return f.string(from: NSNumber(value: spend.amount)) ?? "\(spend.amount) \(spend.currency)"
    }
}
