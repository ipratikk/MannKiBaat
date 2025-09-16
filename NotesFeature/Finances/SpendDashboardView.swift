//
//  SpendDashboardView.swift
//  SpendsFeature
//

import SwiftUI

@MainActor
public struct SpendDashboardView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("Spends Dashboard")
                .font(.title)
                .padding()
            
            Text("Here you’ll see your spending summary, charts, and budget tracking.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("Spends")
    }
}
