import SwiftUI
import SharedModels

struct TodoRowView: View {
    let todo: TodoObject
    
    private var todoDateString: String {
        let date = todo.createdAt
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today • \(date.timeString())" }
        if cal.isDateInYesterday(date) { return "Yesterday • \(date.timeString())" }
        if let days = date.daysAgo(), days <= 30 { return date.dayMonthYearString() }
        if cal.component(.year, from: date) == cal.component(.year, from: Date()) { return date.monthYearString() }
        return date.yearString()
    }
    
    private var itemsPreview: String {
        guard let items = todo.items, !items.isEmpty else { return "" }
        let titles = items.prefix(2).map { $0.title }
        return titles.joined(separator: ", ") + (items.count > 2 ? ", ..." : "")
    }
    
    private var completedText: String {
        let completed = todo.items?.filter { $0.isCompleted }.count ?? 0
        let total = todo.items?.count ?? 0
        return "\(completed)/\(total)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(todo.title).bold().lineLimit(1)
                Spacer()
                Text(completedText).font(.caption).foregroundColor(.secondary)
            }
            if !itemsPreview.isEmpty {
                Text(itemsPreview).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            }
            Text(todoDateString).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
