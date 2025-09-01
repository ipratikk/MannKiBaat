//
//  TodosView.swift
//  MannKiBaat
//

import SwiftUI
import SharedModels
import SwiftData

public struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TodosViewModel
    @State private var newTodo: TodoObject?
    
    public init(viewModel: TodosViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            // Custom gradient background
            GradientBackgroundView()
            
            List {
                ForEach($viewModel.todos) { $todo in
                    NavigationLink(destination: TodoDetailView(todo: todo)) {
                        HStack {
                            // Todo title with strikethrough if all items completed
                            Text(todo.title)
                                .font(.headline)
                                .foregroundColor(todoIsCompleted(todo) ? .gray : .primary)
                                .strikethrough(todoIsCompleted(todo), color: .gray)
                            
                            Spacer()
                            
                            let completed = todo.items?.filter { $0.isCompleted }.count ?? 0
                            let total = todo.items?.count ?? 0
                            Text("\(completed)/\(total)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.clear)
                }
                .onDelete { indexSet in
                    Task {
                        for i in indexSet {
                            await viewModel.removeTodo(viewModel.todos[i], in: modelContext)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // Floating + Button
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
                                            if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                                                todo.title = "New Todo"
                                            }
                                            if !viewModel.todos.contains(where: { $0.id == todo.id }) {
                                                modelContext.insert(todo)
                                                try? await modelContext.save()
                                            }
                                            await viewModel.fetchTodos(in: modelContext)
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
                                .background(
                                    Circle()
                                        .fill(Color.accentColor)
                                        .shadow(radius: 4)
                                )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Todos")
        .task { await viewModel.fetchTodos(in: modelContext) }
    }
    
    // MARK: - Helpers
    private func todoIsCompleted(_ todo: TodoObject) -> Bool {
        guard let items = todo.items, !items.isEmpty else { return false }
        return items.allSatisfy { $0.isCompleted }
    }
}
