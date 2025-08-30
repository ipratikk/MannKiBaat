import SwiftUI
import LoginFeature
import SharedModels
import SwiftData
import NotesFeature

@MainActor
public struct MainAppView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var notesViewModel = NotesViewModel()
    @State private var showProfile = false
    @State private var searchText = ""
    
    public var body: some View {
        TabView {
            NavigationStack {
                NotesView(viewModel: notesViewModel)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                    .navigationTitle("Mann ki Baatein")
                    .toolbar {
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
            .tabItem { Label("Notes", systemImage: "note.text") }
            
            NavigationStack {
                Text("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(loginViewModel: loginViewModel)
        }
    }
}
