//
//  MannKiBaatApp.swift
//

import SwiftUI
import SwiftData
import MannKiBaat
import SharedModels
import LoginFeature
import NotesFeature

@main
struct MannKiBaatApp: App {
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @StateObject private var loginViewModel = LoginViewModel()
    
    // MARK: - Shared Model Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(
            [
                NoteModel.self,
                TodoItem.self,
                TodoObject.self,
                MemoryLane.self,
                MemoryItem.self
            ]
        )
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
                .environmentObject(loginViewModel)
                .modelContainer(sharedModelContainer)
                .onAppear { updateInterfaceStyle() }
                .onChange(of: isDarkMode) { _ in updateInterfaceStyle() }
                .onChange(of: loginViewModel.isLoggedIn) { _ in updateInterfaceStyle() }
        }
    }
    
    private func updateInterfaceStyle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        if loginViewModel.isLoggedIn {
            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        } else {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}
