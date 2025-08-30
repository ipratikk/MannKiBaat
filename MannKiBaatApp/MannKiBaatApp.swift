//
//  MannKiBaatApp.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI
import SwiftData
import MannKiBaat
import SharedModels

@main
struct MannKiBaatApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([NoteModel.self])
        
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .private("iCloud.com.pratik.MannKiBaat")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            fatalError("Failed to create CloudKit ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .modelContainer(sharedModelContainer)
        }
    }
}
