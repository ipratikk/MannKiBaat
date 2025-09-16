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
                
                if let subtitle = rowSubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(formattedOriginalAmount)
                .fontWeight(.medium)
        }
    }
    
    private var rowSubtitle: String? {
        guard let section else {
            return DateDisplayFormatter.formattedRowDate(spend.date)
        }
        switch section {
        case "Today", "Yesterday":
            return spend.date.timeString()
        default:
            return DateDisplayFormatter.formattedRowDate(spend.date)
        }
    }
    
    private var formattedOriginalAmount: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = spend.currency
        return f.string(from: NSNumber(value: spend.amount)) ?? "\(spend.amount) \(spend.currency)"
    }
}
