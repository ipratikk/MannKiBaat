import Combine
import Foundation
import SwiftUI
import SwiftData
import SharedModels

@MainActor
public class TodosViewModel: ObservableObject {
    @Published public var todos: [TodoObject] = []
    @Published public var searchText: String = ""
    
    public init() {}
    
    // Fetch todos from context
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
    
    // Add new todo
    public func addTodo(title: String, in context: ModelContext) async {
        let todo = TodoObject(title: title)
        context.insert(todo)
        try? await context.save()
        todos.insert(todo, at: 0)
    }
    
    // Remove todo
    public func removeTodo(_ todo: TodoObject, in context: ModelContext) async {
        context.delete(todo)
        try? await context.save()
        todos.removeAll { $0.id == todo.id }
    }
    
    // Add item to a todo
    public func addItem(to todo: TodoObject, title: String, in context: ModelContext) async {
        let item = TodoItem(title: title, parent: todo)
        if todo.items == nil { todo.items = [] }
        todo.items?.append(item)
        try? await context.save()
        refresh(todo)
    }
    
    // Toggle item completion
    public func toggleItemCompletion(_ item: TodoItem, in context: ModelContext) async {
        item.isCompleted.toggle()
        item.updatedAt = Date()
        try? await context.save()
        if let todo = item.parent { refresh(todo) }
    }
    
    // Refresh parent todo in array
    func refresh(_ todo: TodoObject) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index] = todo
    }
    
    // Filter todos by search
    public func filteredTodos() -> [TodoObject] {
        guard !searchText.isEmpty else { return todos }
        let lower = searchText.lowercased()
        return todos.filter { $0.title.lowercased().contains(lower) }
    }
    
    // Group todos by creation date (Today / Yesterday / Older)
    public func groupedTodos() -> [String: [TodoObject]] {
        var sections: [String: [TodoObject]] = [:]
        let calendar = Calendar.current
        let now = Date()
        
        for todo in filteredTodos() {
            let date = todo.createdAt
            let key: String
            if calendar.isDateInToday(date) { key = "Today" }
            else if calendar.isDateInYesterday(date) { key = "Yesterday" }
            else { key = "Older" }
            
            sections[key, default: []].append(todo)
        }
        
        // Sort todos inside each section
        for key in sections.keys {
            sections[key]?.sort { $0.createdAt > $1.createdAt }
        }
        
        return sections
    }
}
