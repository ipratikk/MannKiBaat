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
    
    @State private var showSettings = false
    
    public var body: some View {
        TabView {
            // MARK: - Notes Tab
            NavigationStack {
                ZStack {
                    GradientBackgroundView()
                    NotesView(viewModel: notesViewModel)
                        .navigationTitle("Mann ki Baatein")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button { showSettings = true } label: {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                        .overlay(notesPlusButtonOverlay)
                }
            }
            .tabItem { Label("Notes", systemImage: "note.text") }
            
            // MARK: - Todos Tab
            TodosView(viewModel: todosViewModel)
                .tabItem { Label("TODO", systemImage: "checklist") }
        }
        .tint(.primary)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(loginViewModel)
        }
    }
    
    // MARK: - Overlays
    
    private var notesPlusButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink(
                    destination: NoteEditorView(
                        note: NoteModel(),
                        viewModel: notesViewModel,
                        isNewNote: true
                    )
                ) {
                    plusButton
                }
                .padding()
            }
        }
    }
    
    private var plusButton: some View {
        Image(systemName: "plus")
            .font(.title2)
            .foregroundColor(.white)
            .padding()
            .background(Color.buttonBackground)
            .clipShape(Circle())
            .shadow(radius: 4)
    }
}
