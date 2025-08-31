//
//  MainAppView.swift
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
                                        destination: NoteEditorView(
                                            note: NoteModel(),
                                            viewModel: notesViewModel,
                                            isNewNote: true
                                        )
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
            
            // MARK: - TODO Tab
            NavigationStack {
                ZStack {
                    GradientBackgroundView()
                    
                    TodosView(viewModel: todosViewModel)
                        .navigationTitle("TODO")
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            NavigationLink(
                                destination: Group {
                                    if let todo = newTodo {
                                        TodoDetailView(todo: todo)
                                            .onDisappear {
                                                Task {
                                                    // Default title if empty
                                                    if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                                                        todo.title = "New Todo"
                                                    }
                                                    if !todosViewModel.todos.contains(where: { $0.id == todo.id }) {
                                                        modelContext.insert(todo)
                                                        try? await modelContext.save()
                                                    }
                                                    await todosViewModel.fetchTodos(in: modelContext)
                                                    newTodo = nil
                                                }
                                            }
                                    } else {
                                        EmptyView()
                                    }
                                },
                                isActive: Binding(
                                    get: { newTodo != nil },
                                    set: { if !$0 { newTodo = nil } }
                                )
                            ) {
                                Button {
                                    newTodo = TodoObject(title: "")
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.buttonBackground)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                            }
                            .padding()
                        }
                    }
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
        .task {
            await todosViewModel.fetchTodos(in: modelContext)
        }
    }
}
