//
//  MainAppView.swift
//

import SwiftUI
import LoginFeature
import NotesFeature
import SwiftData
import SharedModels

@MainActor
public struct MainAppView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @Environment(\.modelContext) private var modelContext

    @StateObject private var notesViewModel = NotesViewModel()
    @State private var showProfile = false

    public var body: some View {
        TabView {
            NavigationStack {
                NotesView(viewModel: notesViewModel)
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
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                NavigationLink(destination: NoteEditorView(note: NoteModel(), viewModel: notesViewModel)) {
                                    Image(systemName: "plus")
                                        .font(.title2)
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
            }
            .tabItem { Label("Notes", systemImage: "note.text") }

            NavigationStack { Text("Settings") }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(loginViewModel: loginViewModel)
        }
    }
}
