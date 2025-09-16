//
//  SpendRow.swift
//  SpendsFeature
//

import SwiftUI
import SharedModels

struct SpendRow: View {
    let spend: Spend
    var body: some View {
        HStack {
            if let category = spend.category {
                Image(systemName: category.icon).foregroundColor(.blue)
                Text(category.name).font(.headline)
            } else {
                Image(systemName: "tag").foregroundColor(.gray)
                Text("Uncategorized").font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(spend.amount, specifier: "%.2f") \(spend.currency)")
                    .font(.subheadline).fontWeight(.semibold)
                Text(spend.date, style: .date)
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
