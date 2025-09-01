//
//  TodoItemRow.swift
//

import SwiftUI
import SharedModels
import SwiftData

public struct TodoItemRow: View {
    @Binding var item: TodoItem
    let isExpanded: Bool
    let toggleExpanded: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    withAnimation {
                        item.isCompleted.toggle()
                        item.updatedAt = Date()
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isCompleted ? .green : .secondary)
                }
                
                TextField("Task", text: $item.title)
                    .textFieldStyle(.plain)
                
                Button { toggleExpanded() } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded, let due = item.dueDate {
                Text("Due: \(due.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
    }
}
