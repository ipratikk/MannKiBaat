//
//  MannKiBaatApp.swift
//  MannKiBaat
//

import MannKiBaat
import SwiftUI
import SwiftData
import SharedModels
import LoginFeature
import NotesFeature

@main
struct MannKiBaatApp: App {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    // MARK: - Shared Model Container
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
                .environmentObject(LoginViewModel()) // provide login VM for FaceID & login state
                .modelContainer(sharedModelContainer)
                .onAppear {
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                }
        }
    }
}
