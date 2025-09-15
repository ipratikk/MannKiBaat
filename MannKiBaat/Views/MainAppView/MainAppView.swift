import NotesFeature
import LoginFeature
import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct MainAppView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @StateObject private var notesViewModel = NotesViewModel()
    @StateObject private var todosViewModel = TodosViewModel()
    @StateObject private var memoryViewModel = MemoryViewModel()
    
    @State private var showSettings = false
    
    public var body: some View {
        TabView {
            // MARK: - Notes Tab
            NavigationStack {
                NotesView(viewModel: notesViewModel)
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Notes", systemImage: "note.text") }
            
            // MARK: - Todos Tab
            NavigationStack {
                TodosView(viewModel: todosViewModel)
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("TODO", systemImage: "checklist") }
            
            // MARK: - Memory Lane Tab
            NavigationStack {
                MemoryListView(viewModel: memoryViewModel)
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Memory Lane", systemImage: "clock.arrow.circlepath") }
        }
        .tint(.primary)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(loginViewModel)
        }
    }
    
    // MARK: - Shared Settings Toolbar
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gear")
            }
        }
    }
}
