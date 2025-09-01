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
    @State private var newTodo: TodoObject? = nil
    
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
                    todoPlusButtonOverlay
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
                if let todo = newTodo {
                    NavigationLink(
                        destination: TodoDetailView(todo: todo, viewModel: todosViewModel)
                            .onDisappear {
                                Task {
                                    if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                                        todo.title = "New Todo"
                                    }
                                    // Insert into modelContext to make it appear in TodosView
                                    modelContext.insert(todo)
                                    try? await modelContext.save()
                                    newTodo = nil
                                }
                            },
                        isActive: Binding(get: { newTodo != nil }, set: { if !$0 { newTodo = nil } })
                    ) {
                        plusButton
                    }
                } else {
                    Button {
                        newTodo = TodoObject(title: "")
                    } label: {
                        plusButton
                    }
                }
            }
            .padding()
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
