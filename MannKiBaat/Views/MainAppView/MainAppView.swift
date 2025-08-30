//
//  MainAppView.swift
//  MannKiBaat
//

import SwiftUI
import LoginFeature
import NotesFeature
import SharedModels

@MainActor
struct MainAppView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @StateObject private var notesViewModel = NotesViewModel(notesManager: NotesManager(syncService: SyncManager()))
    @State private var showNewNote = false

    var body: some View {
        NavigationStack {
            NotesView(viewModel: notesViewModel)
                .navigationTitle("My Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button("New Note") {
                                showNewNote = true
                            }
                            Button("Logout") {
                                loginViewModel.logout()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .sheet(isPresented: $showNewNote) {
                    NewNoteView(viewModel: notesViewModel)
                }
        }
    }
}
