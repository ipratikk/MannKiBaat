//
//  TodosViewModel.swift
//  MannKiBaat
//

import Combine
import Foundation
import SharedModels
import SwiftUI
import SwiftData

@MainActor
public class TodosViewModel: ObservableObject {
    @Published public var todos: [TodoObject] = []
    
    public init() {}
    
    // MARK: - Fetch
    public func fetchTodos(in context: ModelContext) async {
        do {
            let request = FetchDescriptor<TodoObject>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            todos = try await context.fetch(request)
        } catch {
            print("Failed to fetch todos:", error)
            todos = []
        }
    }
    
    // MARK: - Add Todo
    public func addTodo(title: String, in context: ModelContext) async {
        let todo = TodoObject(title: title, items: [])
        context.insert(todo)
        try? await context.save()
        await fetchTodos(in: context)
    }
    
    // MARK: - Remove Todo
    public func removeTodo(_ todo: TodoObject, in context: ModelContext) async {
        context.delete(todo)
        try? await context.save()
        await fetchTodos(in: context)
    }
    
    // MARK: - Add Item
    public func addItem(to todo: TodoObject, title: String, in context: ModelContext) async {
        let item = TodoItem(title: title, parent: todo)
        if todo.items == nil {
            todo.items = []
        }
        todo.items?.append(item)
        try? await context.save()
        await fetchTodos(in: context)
    }
    
    // MARK: - Toggle Completion
    public func toggleItemCompletion(_ item: TodoItem, in context: ModelContext) async {
        item.isCompleted.toggle()
        try? await context.save()
        await fetchTodos(in: context)
    }
}
