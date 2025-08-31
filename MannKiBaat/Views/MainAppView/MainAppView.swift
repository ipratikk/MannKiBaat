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
    @State private var showSettings = false
    
    public var body: some View {
        TabView {
            // MARK: - Notes Tab
            NavigationStack {
                ZStack {
                    IconGeneratorTestView()
                    GradientBackgroundView()
                    
                    NotesView(viewModel: notesViewModel)
                        .navigationTitle("Mann ki Baatein")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                        .overlay(
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    NavigationLink(
                                        destination: NoteEditorView(note: NoteModel(), viewModel: notesViewModel, isNewNote: true)
                                    ) {
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
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            
            // MARK: - Settings Tab (Placeholder)
            NavigationStack {
                ZStack {
                    GradientBackgroundView()
                    Text("Settings")
                        .foregroundColor(.primary)
                }
            }
            .tabItem {
                Label("TODO", systemImage: "checklist")
            }
        }
        .tint(Color.primary)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(loginViewModel) // inject EnvironmentObject
        }
    }
}
