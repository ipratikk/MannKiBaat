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
    
    // Optional due/reminder
    @State private var newItemDueDate: Date? = nil
    @State private var newItemReminderEnabled: Bool = false
    @State private var newItemReminderMinutesBefore: Int = 5
    @State private var newItemTags: String = ""
    
    @FocusState private var isTitleFocused: Bool
    
    @State private var expandedTaskID: UUID? = nil
    
    // New states to control showing inputs in toolbar
    @State private var showTagsField = false
    @State private var showCustomDueDateSheet = false
    
    public init(todo: TodoObject) {
        self._todo = Bindable(todo)
    }
    
    private var incompleteItems: [TodoItem] {
        (todo.items ?? []).filter { !$0.isCompleted }
    }
    private var completedItems: [TodoItem] {
        (todo.items ?? []).filter { $0.isCompleted }
    }
    
    // Binding helper
    private func binding(for item: TodoItem) -> Binding<TodoItem>? {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }) else { return nil }
        return Binding(
            get: { todo.items![index] },
            set: { todo.items![index] = $0; try? modelContext.save() }
        )
    }
    
    public var body: some View {
        VStack {
            // Large editable title
            TextField("New Todo", text: $todo.title)
                .font(.largeTitle.bold())
                .padding(.horizontal)
                .padding(.top)
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
            List {
                // Incomplete
                ForEach(incompleteItems, id: \.id) { item in
                    if let binding = binding(for: item) {
                        TodoItemRow(
                            item: binding,
                            isExpanded: expandedTaskID == item.id,
                            toggleExpanded: {
                                withAnimation {
                                    expandedTaskID = (expandedTaskID == item.id) ? nil : item.id
                                }
                            }
                        )
                    }
                }
                .onDelete(perform: deleteItems)
                
                // Completed
                if !completedItems.isEmpty {
                    Section("Completed") {
                        ForEach(completedItems, id: \.id) { item in
                            if let binding = binding(for: item) {
                                TodoItemRow(
                                    item: binding,
                                    isExpanded: expandedTaskID == item.id,
                                    toggleExpanded: {
                                        withAnimation {
                                            expandedTaskID = (expandedTaskID == item.id) ? nil : item.id
                                        }
                                    }
                                )
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                
                // New task input section
                Section {
                    NewTaskInputView(
                        title: $newItemTitle,
                        dueDate: $newItemDueDate,
                        addAction: addNewItem
                    )
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                TodoToolbarView(
                    dueDate: $newItemDueDate,
                    showTagsField: $showTagsField,
                    showCustomDueDateSheet: $showCustomDueDateSheet,
                    tags: $newItemTags
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showTagsField {
                // Only show tags field section, logic is in KeyboardToolbarView
                VStack(spacing: 8) {
                    let tags = newItemTags.split(separator: " ").map(String.init)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.secondary.opacity(0.2)))
                            }
                            TextField("Add tag", text: $newItemTags)
                                .font(.caption)
                                .frame(minWidth: 50)
                        }
                        .padding(.horizontal)
                    }
                }
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showCustomDueDateSheet) {
            CustomDueDateSheet(
                dueDate: $newItemDueDate,
                reminderEnabled: $newItemReminderEnabled,
                reminderMinutesBefore: $newItemReminderMinutesBefore,
                isPresented: $showCustomDueDateSheet
            )
        }
    }
    
    // MARK: - Task Cell
    // Task Cell logic moved to TodoItemRow.swift
    
    // MARK: - Actions
    private func deleteItems(at offsets: IndexSet) {
        for idx in offsets {
            if let item = todo.items?[idx] {
                modelContext.delete(item)
            }
        }
        try? modelContext.save()
    }
    
    private func addNewItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newItem = TodoItem(
            title: trimmed,
            dueDate: newItemDueDate,
            reminderDate: newItemReminderEnabled ? newItemDueDate : nil,
            remindBeforeMinutes: newItemReminderEnabled ? newItemReminderMinutesBefore : nil
        )
        if todo.items == nil { todo.items = [] }
        todo.items?.append(newItem)
        try? modelContext.save()
        newItemTitle = ""
        newItemDueDate = nil
        newItemReminderEnabled = false
        newItemReminderMinutesBefore = 5
        newItemTags = ""
        showCustomDueDateSheet = false
        showTagsField = false
    }
}
