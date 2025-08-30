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
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 20) {
                    // + Button
                    Spacer()
                    
                    Button {
                        showNewNote = true
                    } label: {
                        Image(systemName: "plus")
                            .padding(8)
                            .tint(Color.primary)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    // Profile Button
                    Button {
                        showProfile = true
                    } label: {
                        Image("Manasa")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                // Title
                Text("Mann ki Baatein")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                
                // Notes list
                NotesView(viewModel: notesViewModel)
                
                Spacer()
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
