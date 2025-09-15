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
        let today = Date()
        
        for todo in filteredTodos(from: todos) {
            let date = todo.createdAt
            let key: String
            if calendar.isDateInToday(date) {
                key = "Today"
            } else if calendar.isDateInYesterday(date) {
                key = "Yesterday"
            } else if let daysAgo = date.daysAgo(), daysAgo <= 30 {
                key = "Last 30 Days"
            } else if calendar.isDate(date, equalTo: today, toGranularity: .year) {
                key = date.monthYearString()
            } else {
                key = date.yearString()
            }
            sections[key, default: []].append(todo)
        }
        
        for key in sections.keys {
            sections[key]?.sort { $0.createdAt > $1.createdAt }
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
    
    // MARK: - Refresh
    public func refresh(_ context: ModelContext) async {
        try? await context.save()
    }
}

// MARK: - Display Helpers for Row Rendering
extension TodosViewModel {
    public func formattedCompletedText(for todo: TodoObject) -> String {
        let completed = todo.items?.filter { $0.isCompleted }.count ?? 0
        let total = todo.items?.count ?? 0
        return "\(completed)/\(total)"
    }
    
    public func formattedItemsPreview(for todo: TodoObject, limit: Int = 2) -> String {
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
