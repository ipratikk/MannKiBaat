//
//  MannKiBaatApp.swift
//  MannKiBaat
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
                .environmentObject(loginViewModel)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    applyInterfaceStyle()
                }
                .onChange(of: loginViewModel.isLoggedIn) { loggedIn in
                    // Apply dark/light mode only when logged in, reset to system default on logout
                    applyInterfaceStyle()
                }
        }
    }
    
    private func applyInterfaceStyle() {
        if loginViewModel.isLoggedIn {
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        } else {
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .unspecified
        }
    }
}
