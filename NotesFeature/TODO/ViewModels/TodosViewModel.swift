import Combine
import SwiftUI
import SwiftData
import SharedModels

@MainActor
public class TodosViewModel: ObservableObject {
    @Published var searchText: String = ""
    
    public init() {}
    
    // Filter todos based on search text
    public func filteredTodos(from todos: [TodoObject]) -> [TodoObject] {
        guard !searchText.isEmpty else { return todos }
        let query = searchText.lowercased()
        return todos.filter { todo in
            todo.title.lowercased().contains(query) ||
            (todo.items?.contains { $0.title.lowercased().contains(query) } ?? false)
        }
    }
    
    // Group todos by date section
    public func groupedTodos(_ todos: [TodoObject]) -> [String: [TodoObject]] {
        var sections: [String: [TodoObject]] = [:]
        let calendar = Calendar.current
        let now = Date()
        
        for todo in filteredTodos(from: todos) {
            let date = todo.createdAt
            let section: String
            if calendar.isDateInToday(date) {
                section = "Today"
            } else if calendar.isDateInYesterday(date) {
                section = "Yesterday"
            } else {
                section = "Older"
            }
            sections[section, default: []].append(todo)
        }
        
        return sections
    }
    
    // MARK: - CRUD
    public func addTodo(title: String, in context: ModelContext) async {
        let todo = TodoObject(title: title)
        context.insert(todo)
        try? await context.save()
    }
    
    public func removeTodo(_ todo: TodoObject, in context: ModelContext) async {
        context.delete(todo)
        try? await context.save()
    }
    
    public func toggleItemCompletion(_ item: TodoItem, in context: ModelContext) async {
        item.isCompleted.toggle()
        item.updatedAt = Date()
        try? await context.save()
    }
    
    public func addItem(to todo: TodoObject, title: String, in context: ModelContext) async {
        let item = TodoItem(title: title)
        todo.items?.append(item)
        context.insert(item)
        try? await context.save()
    }
}
