import NotesFeature
import LoginFeature
import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct MainAppView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @Environment(\.modelContext) private var modelContext
    
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
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            
            // MARK: - TODO Tab
            NavigationStack {
                ZStack {
                    GradientBackgroundView()
                    TodosView(viewModel: todosViewModel)
                        .navigationTitle("TODO")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button { showSettings = true } label: {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                        .overlay(todoPlusButtonOverlay)
                }
            }
            .tabItem {
                Label("TODO", systemImage: "checklist")
            }
        }
        .tint(Color.primary)
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
    
    private var todoPlusButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink(
                    destination: TodoDetailView(
                        todo: TodoObject(title: ""), // always create a new Todo here
                        viewModel: todosViewModel
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
