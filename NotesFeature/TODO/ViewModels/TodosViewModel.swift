import Combine
import SwiftUI
import SwiftData
import SharedModels

@MainActor
public class TodosViewModel: ObservableObject {
    @Published var searchText: String = ""
    
    public init() {}
    
    // MARK: - Filtering
    public func filteredTodos(from todos: [TodoObject]) -> [TodoObject] {
        guard !searchText.isEmpty else { return todos }
        let query = searchText.lowercased()
        return todos.filter { todo in
            todo.title.lowercased().contains(query) ||
            (todo.items?.contains { $0.title.lowercased().contains(query) } ?? false)
        }
    }
    
    // MARK: - Grouping
    public func groupedTodos(_ todos: [TodoObject]) -> [String: [TodoObject]] {
        var sections: [String: [TodoObject]] = [:]
        let calendar = Calendar.current
        
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
    
    // MARK: - CRUD (sync saves)
    
    public func addTodo(title: String, in context: ModelContext) {
        let todo = TodoObject(title: title)
        context.insert(todo)
        try? context.save()
    }
    
    public func removeTodo(_ todo: TodoObject, in context: ModelContext) {
        context.delete(todo)
        try? context.save()
    }
    
    public func toggleItemCompletion(_ item: TodoItem, in context: ModelContext) {
        item.isCompleted.toggle()
        item.updatedAt = Date()
        try? context.save()
    }
    
    public func addItem(to todo: TodoObject, title: String, in context: ModelContext) {
        let item = TodoItem(title: title, parent: todo)
        todo.items?.append(item)
        context.insert(item)
        try? context.save()
    }
    
    public func deleteItem(_ item: TodoItem, in context: ModelContext) {
        context.delete(item)
        try? context.save()
    }
}

extension TodosViewModel {
    // MARK: - Helpers for Row Rendering
    public func completedText(for todo: TodoObject) -> String {
        let completed = todo.items?.filter { $0.isCompleted }.count ?? 0
        let total = todo.items?.count ?? 0
        return "\(completed)/\(total)"
    }
    
    public func itemsPreview(for todo: TodoObject, limit: Int = 2) -> String {
        guard let items = todo.items, !items.isEmpty else { return "" }
        let titles = items.prefix(limit).map { $0.title }
        return titles.joined(separator: ", ") + (items.count > limit ? ", ..." : "")
    }
    
    public func formattedDateString(for todo: TodoObject) -> String {
        let date = todo.createdAt
        let cal = Calendar.current
        if cal.isDateInToday(date) { return date.timeString() }
        if cal.isDateInYesterday(date) { return date.timeString() }
        if let days = date.daysAgo(), days <= 30 { return date.dayMonthYearString() }
        if cal.component(.year, from: date) == cal.component(.year, from: Date()) {
            return date.monthYearString()
        }
        return date.yearString()
    }
}
