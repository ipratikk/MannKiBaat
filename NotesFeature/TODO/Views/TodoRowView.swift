import SwiftUI
import SharedModels

public struct TodoRowView: View {
    let todo: TodoObject
    
    private var dateString: String {
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
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(todo.title).bold().lineLimit(1)
                Spacer()
                Text(completedText).font(.caption).foregroundColor(.secondary)
            }
            if !itemsPreview.isEmpty {
                Text(itemsPreview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Text(dateString).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
