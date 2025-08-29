//
//  MainAppView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI

struct MainAppView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Main App Screen")
                    .font(.title)

                NavigationLink("Go to Next Page") {
                    Text("Another screen")
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

#Preview("Light Mode") {
    MainAppView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    MainAppView()
        .preferredColorScheme(.dark)
}
