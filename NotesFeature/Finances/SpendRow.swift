//
//  SpendRow.swift
//  SpendsFeature
//

import SwiftUI
import SharedModels

public struct SpendRow: View {
    let spend: Spend
    
    public init(spend: Spend) {
        self.spend = spend
    }
    
    public var body: some View {
        HStack {
            Label(spend.category?.name ?? "Others", systemImage: spend.category?.icon ?? "tag")
                .labelStyle(.titleAndIcon)
            
            Spacer()
            
            Text(formattedOriginalAmount)
                .fontWeight(.medium)
        }
    }
    
    private var formattedOriginalAmount: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = spend.currency
        return f.string(from: NSNumber(value: spend.amount)) ?? "\(spend.amount) \(spend.currency)"
    }
}
