//
//  TodoRowView.swift
//  MannKiBaat
//

import SwiftUI
import SharedModels

struct TodoRowView: View {
    let todo: TodoObject
    
    // MARK: - Date String Logic
    private var todoDateString: String {
        let date = todo.createdAt
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today • \(date.timeString())"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday • \(date.timeString())"
        } else if let daysAgo = date.daysAgo(), daysAgo <= 30 {
            return date.dayMonthYearString() // e.g., Aug 10, 2025
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: Date()) {
            return date.monthYearString() // e.g., July 2025
        } else {
            return date.yearString() // e.g., 2024
        }
    }
    
    // MARK: - Items Preview
    private var itemsPreview: String {
        guard let items = todo.items, !items.isEmpty else { return "" }
        let titles = items.prefix(2).map { $0.title }
        return titles.joined(separator: ", ") + (items.count > 2 ? ", ..." : "")
    }
    
    // MARK: - Completed Count Text
    private var completedText: String {
        let completedCount = todo.items?.filter { $0.isCompleted }.count ?? 0
        let totalCount = todo.items?.count ?? 0
        return "\(completedCount)/\(totalCount)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(todo.title)
                    .bold()
                    .lineLimit(1)
                Spacer()
                Text(completedText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !itemsPreview.isEmpty {
                Text(itemsPreview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text(todoDateString)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
