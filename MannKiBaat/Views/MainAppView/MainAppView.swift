import SwiftUI
import LoginFeature
import NotesFeature
import SharedModels
import SwiftData

@MainActor
public struct MainAppView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @Environment(\.modelContext) private var modelContext

    @StateObject private var notesViewModel: NotesViewModel
    @State private var showNewNote = false
    @State private var showProfile = false
    @State private var searchText = ""

    public init(modelContext: ModelContext) {
        _notesViewModel = StateObject(
            wrappedValue: NotesViewModel(
                notesManager: NotesManager(
                    container: modelContext,
                    syncService: SyncManager()
                )
            )
        )
    }

    public var body: some View {
        TabView {
            NavigationStack {
                NotesView(viewModel: notesViewModel)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                    .navigationTitle("Mann ki Baatein")
                    .toolbar {
                        // Profile button in navigation bar
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showProfile = true
                            } label: {
                                Image("Manasa")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            }
                        }
                    }
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }

            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        // Floating add note button
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showNewNote = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.buttonBackground)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $showNewNote) {
            NewNoteView(viewModel: notesViewModel)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(loginViewModel: loginViewModel)
        }
        .task {
            await notesViewModel.fetchNotes()
        }
    }
}
