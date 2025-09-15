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
    
    // MARK: - CRUD
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
    
    // MARK: - Pin
    public func togglePin(for item: TodoItem, in context: ModelContext) {
        item.isPinned.toggle()
        try? context.save()
    }
    
    // MARK: - Reordering
    public func reorderItems(
        pinnedItems: [TodoItem],
        normalItems: [TodoItem],
        movedArray: [TodoItem],
        indices: IndexSet,
        newOffset: Int,
        in context: ModelContext
    ) {
        var pinned = pinnedItems
        var normal = normalItems
        
        if movedArray.first?.isPinned == true {
            pinned.move(fromOffsets: indices, toOffset: newOffset)
        } else {
            normal.move(fromOffsets: indices, toOffset: newOffset)
        }
        
        let merged = pinned + normal
        for (idx, item) in merged.enumerated() {
            item.orderIndex = idx
        }
        try? context.save()
    }
    
    // MARK: - Title fixing
    public func saveOrFixTitle(for todo: TodoObject, in context: ModelContext) {
        if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
            todo.title = "New Todo"
        }
        try? context.save()
    }
}
