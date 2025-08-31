//
//  TodosView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 31/08/25.
//

import SwiftUI
import SharedModels
import SwiftData

public struct TodosView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TodosViewModel
    
    // Track the new todo for navigation
    @State private var newTodo: TodoObject?
    
    public init(viewModel: TodosViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            
            List {
                ForEach(viewModel.todos, id: \.id) { todo in
                    NavigationLink(destination: TodoDetailView(todo: todo)) {
                        HStack {
                            Text(todo.title)
                                .font(.headline)
                            Spacer()
                            let completedCount = todo.items?.filter { $0.isCompleted }.count ?? 0
                            let totalCount = todo.items?.count ?? 0
                            Text("\(completedCount)/\(totalCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for i in indexSet {
                            await viewModel.removeTodo(viewModel.todos[i], in: modelContext)
                        }
                    }
                }
            }
            
            // Floating Add Button
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
                                .background(Color.buttonBackground)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }

                    .padding()
                }
            }
        }
        .navigationTitle("TODO")
        .task { await viewModel.fetchTodos(in: modelContext) }
    }
}
