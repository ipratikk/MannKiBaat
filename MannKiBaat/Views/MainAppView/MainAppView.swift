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
        NavigationStack {
            ZStack {
                // Main content
                NotesView(viewModel: notesViewModel)
                    .navigationTitle("Mann ki Baatein")
                    .toolbar {
                        // Profile button on navigation bar
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

                // Floating + Button
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
                                .background(Color.themeForest.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
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
}
