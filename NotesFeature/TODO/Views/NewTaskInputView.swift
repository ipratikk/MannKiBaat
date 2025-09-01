//  NewTaskInputView.swift

import SwiftUI
import SharedModels

public struct NewTaskInputView: View {
    @Binding var newItem: TodoItem
    let addAction: (TodoItem) -> Void
    @State private var showCustomDueDateSheet = false
    
    public init(newItem: Binding<TodoItem>, addAction: @escaping (TodoItem) -> Void) {
        self._newItem = newItem
        self.addAction = addAction
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("New Task", text: $newItem.title)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                
                Button(action: { addAction(newItem) }) {
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
        .sheet(isPresented: $showCustomDueDateSheet) {
            CustomDueDateSheet(
                dueDate: $newItem.dueDate,
                reminderEnabled: Binding(
                    get: { newItem.reminderDate != nil },
                    set: { newValue in newItem.reminderDate = newValue ? newItem.dueDate : nil }
                ),
                reminderMinutesBefore: Binding(
                    get: { newItem.remindBeforeMinutes ?? 5 },
                    set: { newItem.remindBeforeMinutes = $0 }
                ),
                isPresented: $showCustomDueDateSheet
            )
        }
    }
}
