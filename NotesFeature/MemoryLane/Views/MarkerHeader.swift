//
//  MarkerHeader.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 16/09/25.
//


import SwiftUI

struct MarkerHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.footnote.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemBackground).opacity(0.9))
                .clipShape(Capsule())
                .shadow(radius: 1)
            Spacer()
        }
        .padding(.bottom, 8)
    }
}
