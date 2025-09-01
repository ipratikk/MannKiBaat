//  NewTaskInputView.swift

import SwiftUI
import SharedModels

public struct NewTaskInputView: View {
    @Binding var newItem: TodoItem
    @Binding var showCustomDueDateSheet: Bool
    let addAction: (TodoItem) -> Void
    
    public init(
        newItem: Binding<TodoItem>,
        showCustomDueDateSheet: Binding<Bool>,
        addAction: @escaping (TodoItem) -> Void
    ) {
        self._newItem = newItem
        self._showCustomDueDateSheet = showCustomDueDateSheet
        self.addAction = addAction
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("New Task", text: $newItem.title)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                
                Button {
                    addAction(newItem)
                    newItem = TodoItem()
                    // Reset the sheet state when adding a new item
                    showCustomDueDateSheet = false
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .disabled(newItem.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            if let due = newItem.dueDate {
                HStack(spacing: 8) {
                    Text("Due by:")
                        .font(.caption)
                    
                    Button { showCustomDueDateSheet = true } label: {
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(16)
                            .font(.caption)
                    }
                    
                    Button { showCustomDueDateSheet = true } label: {
                        Text(due.formatted(date: .omitted, time: .shortened))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(16)
                            .font(.caption)
                    }
                    
                    if newItem.reminderDate != nil {
                        Button { showCustomDueDateSheet = true } label: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.yellow)
                                .padding(6)
                                .background(Circle().fill(Color.secondary.opacity(0.2)))
                        }
                    }
                }
            }
        }
        // Remove the duplicate sheet - it's now handled in TodoDetailView
    }
}
