//
//  MainAppView.swift
//  MannKiBaat
//

//
//  MainAppView.swift
//  MannKiBaat
//

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
                .task {
                    await notesViewModel.fetchNotes()
                }
        }
    }
}
