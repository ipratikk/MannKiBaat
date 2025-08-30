//
//  MannKiBaatApp.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI
import SwiftData
import MannKiBaat

@main
struct MannKiBaatApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppEntryView()
        }
        .modelContainer(sharedModelContainer)
    }
}

#Preview("Light Mode") {
    AppEntryView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AppEntryView()
        .preferredColorScheme(.dark)
}
