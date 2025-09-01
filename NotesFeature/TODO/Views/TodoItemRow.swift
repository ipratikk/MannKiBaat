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
    
    public init(item: Binding<TodoItem>, isExpanded: Bool, toggleExpanded: @escaping () -> Void) {
        self._item = item
        self.isExpanded = isExpanded
        self.toggleExpanded = toggleExpanded
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    withAnimation {
                        item.isCompleted.toggle()
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isCompleted ? .green : .secondary)
                }
                
                TextField("Task", text: $item.title)
                    .textFieldStyle(.plain)
                
                Button {
                    toggleExpanded()
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let due = $item.wrappedValue.dueDate {
                        Text("Due: \(due.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
//                    if let tags = $item.wrappedValue.tags, !tags.isEmpty {
//                        HStack {
//                            ForEach(tags, id: \.self) { tag in
//                                Text(tag)
//                                    .font(.caption)
//                                    .padding(.horizontal, 8)
//                                    .padding(.vertical, 2)
//                                    .background(Capsule().fill(Color.secondary.opacity(0.2)))
//                            }
//                        }
//                    }
                }
                .padding(.leading, 28)
            }
        }
    }
}
