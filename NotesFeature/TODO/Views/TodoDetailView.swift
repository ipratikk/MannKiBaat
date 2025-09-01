//
//  TodoDetailView.swift
//

import SwiftUI
import SharedModels
import SwiftData

public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    
    @State private var newItemTitle: String = ""
    @State private var newItemDueDate: Date = Date()
    @State private var newItemReminder: Date = Date()
    @State private var newItemRemindBefore: Int = 0
    @State private var newTaskExpanded: Bool = false
    
    @FocusState private var isTitleFocused: Bool
    @State private var expandedTaskIDs: Set<UUID> = []
    
    public init(todo: TodoObject) {
        self._todo = Bindable(todo)
    }
    
    private var incompleteItems: [TodoItem] {
        (todo.items ?? [])
            .filter { !$0.isCompleted }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    private var completedItems: [TodoItem] {
        (todo.items ?? [])
            .filter { $0.isCompleted }
            .sorted { ($0.updatedAt ?? $0.createdAt) < ($1.updatedAt ?? $1.createdAt) }
    }
    
    private func binding(for item: TodoItem) -> Binding<TodoItem>? {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }) else { return nil }
        return Binding(
            get: { todo.items![index] },
            set: { updated in
                todo.items![index] = updated
                todo.items![index].updatedAt = Date()
                try? modelContext.save()
            }
        )
    }
    
    public var body: some View {
        VStack {
            // Editable large title
            TextField("New Todo", text: $todo.title)
                .font(.largeTitle.bold())
                .padding(.horizontal)
                .padding(.top)
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onAppear {
                    if todo.title.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTitleFocused = true
                        }
                    }
                }
            
            List {
                if !incompleteItems.isEmpty {
                    Section("Tasks") {
                        ForEach(incompleteItems, id: \.id) { item in
                            if let itemBinding = binding(for: item) {
                                taskRow(itemBinding: itemBinding)
                            }
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    }
                }
                
                if !completedItems.isEmpty {
                    Section("Completed") {
                        ForEach(completedItems, id: \.id) { item in
                            if let itemBinding = binding(for: item) {
                                taskRow(itemBinding: itemBinding)
                            }
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    }
                }
                
                // Collapsible new task row
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("New Task", text: $newItemTitle)
                                .textFieldStyle(.plain)
                            
                            Spacer()
                            
                            Button(action: { newTaskExpanded.toggle() }) {
                                Image(systemName: newTaskExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: addNewItem) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                            .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        
                        if newTaskExpanded {
                            VStack(alignment: .leading, spacing: 8) {
                                DatePicker("Due Date", selection: $newItemDueDate, displayedComponents: [.date, .hourAndMinute])
                                
                                DatePicker("Reminder", selection: $newItemReminder, displayedComponents: [.date, .hourAndMinute])
                                
                                Stepper("Remind \(newItemRemindBefore) min before",
                                        value: $newItemRemindBefore,
                                        in: 0...120,
                                        step: 5)
                            }
                            .font(.caption)
                            .padding(.leading, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Task Row
    @ViewBuilder
    private func taskRow(itemBinding: Binding<TodoItem>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Completion toggle
                Button {
                    withAnimation {
                        itemBinding.wrappedValue.isCompleted.toggle()
                        itemBinding.wrappedValue.updatedAt = Date()
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: itemBinding.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(itemBinding.wrappedValue.isCompleted ? .green : .secondary)
                }
                
                // Editable title
                TextField("Task", text: Binding(
                    get: { itemBinding.wrappedValue.title },
                    set: { itemBinding.wrappedValue.title = $0; itemBinding.wrappedValue.updatedAt = Date(); try? modelContext.save() }
                ))
                .textFieldStyle(.plain)
                .strikethrough(itemBinding.wrappedValue.isCompleted, color: .secondary)
                .foregroundColor(itemBinding.wrappedValue.isCompleted ? .secondary : .primary)
                
                Spacer()
                
                // Chevron for expansion
                Button {
                    toggleExpanded(for: itemBinding.wrappedValue.id)
                } label: {
                    Image(systemName: expandedTaskIDs.contains(itemBinding.wrappedValue.id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if expandedTaskIDs.contains(itemBinding.wrappedValue.id) {
                VStack(alignment: .leading, spacing: 8) {
                    DatePicker("Due Date", selection: Binding(
                        get: { itemBinding.wrappedValue.dueDate ?? Date() },
                        set: { itemBinding.wrappedValue.dueDate = $0; itemBinding.wrappedValue.updatedAt = Date(); try? modelContext.save() }
                    ), displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("Reminder", selection: Binding(
                        get: { itemBinding.wrappedValue.reminderDate ?? Date() },
                        set: { itemBinding.wrappedValue.reminderDate = $0; itemBinding.wrappedValue.updatedAt = Date(); try? modelContext.save() }
                    ), displayedComponents: [.date, .hourAndMinute])
                    
                    Stepper("Remind \(itemBinding.wrappedValue.remindBeforeMinutes ?? 0) min before",
                            value: Binding(
                                get: { itemBinding.wrappedValue.remindBeforeMinutes ?? 0 },
                                set: { itemBinding.wrappedValue.remindBeforeMinutes = $0; itemBinding.wrappedValue.updatedAt = Date(); try? modelContext.save() }
                            ), in: 0...120, step: 5)
                }
                .font(.caption)
                .padding(.leading, 28)
            }
        }
    }
    
    // MARK: - Helpers
    private func toggleExpanded(for id: UUID) {
        if expandedTaskIDs.contains(id) {
            expandedTaskIDs.remove(id)
        } else {
            expandedTaskIDs.insert(id)
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            for idx in offsets {
                if let item = todo.items?[idx] {
                    modelContext.delete(item)
                }
            }
            try? modelContext.save()
        }
    }
    
    private func moveItems(from: IndexSet, to: Int) {
        withAnimation {
            todo.items?.move(fromOffsets: from, toOffset: to)
            try? modelContext.save()
        }
    }
    
    private func addNewItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        withAnimation {
            let newItem = TodoItem(
                title: trimmed,
                dueDate: newItemDueDate,
                reminderDate: newItemReminder,
                remindBeforeMinutes: newItemRemindBefore
            )
            if todo.items == nil { todo.items = [] }
            todo.items?.append(newItem)
            try? modelContext.save()
            
            // Reset inputs
            newItemTitle = ""
            newItemDueDate = Date()
            newItemReminder = Date()
            newItemRemindBefore = 0
            newTaskExpanded = false
        }
    }
}
