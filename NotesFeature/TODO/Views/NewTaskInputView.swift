//
//  NewTaskInputView.swift
//

import SwiftUI
import SharedModels

public struct NewTaskInputView: View {
    @Binding var title: String
    @Binding var dueDate: Date?
    let addAction: () -> Void
    
    public init(title: Binding<String>, dueDate: Binding<Date?>, addAction: @escaping () -> Void) {
        self._title = title
        self._dueDate = dueDate
        self.addAction = addAction
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("New Task", text: $title)
                    .textFieldStyle(.plain)
                Button(action: addAction) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            if let due = dueDate {
                HStack {
                    Label {
                        Text("Due by \(due.formatted(date: .abbreviated, time: .shortened))")
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}
