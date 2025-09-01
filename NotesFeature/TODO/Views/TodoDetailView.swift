// TodoDetailView.swift

import SwiftUI
import SharedModels
import SwiftData

public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    
    @State private var newItem = TodoItem()
    @FocusState private var isTitleFocused: Bool
    @State private var showCustomDueDateSheet = false
    @State private var isAddingItem = false  // Flag to prevent sheet during add
    
    public init(todo: TodoObject) {
        self._todo = Bindable(todo)
    }
    
    private var incompleteItems: [TodoItem] {
        todo.items?.filter { !$0.isCompleted } ?? []
    }
    
    private var completedItems: [TodoItem] {
        todo.items?.filter { $0.isCompleted } ?? []
    }
    
    private func binding(for item: TodoItem) -> Binding<TodoItem>? {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }) else { return nil }
        return Binding(
            get: { todo.items![index] },
            set: { todo.items![index] = $0; try? modelContext.save() }
        )
    }
    
    public var body: some View {
        VStack {
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
                // Single list with incomplete first, completed next
                if let items = todo.items {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        TodoItemRow(
                            item: Binding(
                                get: { todo.items![index] },
                                set: { todo.items![index] = $0 }
                            ),
                            isExpanded: false,
                            toggleExpanded: {}
                        )
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(item: todo.items![index])
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                
                // New Task Input - simplified without sheet binding
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("New Task", text: $newItem.title)
                                .textFieldStyle(.plain)
                                .padding(.vertical, 8)
                            
                            Button {
                                addNewItem(newItem)
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
                                
                                Button {
                                    if !isAddingItem {
                                        showCustomDueDateSheet = true
                                    }
                                } label: {
                                    Text(due.formatted(date: .abbreviated, time: .omitted))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(16)
                                        .font(.caption)
                                }
                                
                                Button {
                                    if !isAddingItem {
                                        showCustomDueDateSheet = true
                                    }
                                } label: {
                                    Text(due.formatted(date: .omitted, time: .shortened))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(16)
                                        .font(.caption)
                                }
                                
                                if newItem.reminderDate != nil {
                                    Button {
                                        if !isAddingItem {
                                            showCustomDueDateSheet = true
                                        }
                                    } label: {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(.yellow)
                                            .padding(6)
                                            .background(Circle().fill(Color.secondary.opacity(0.2)))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Keyboard toolbar integration
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Menu {
                        Button("None", systemImage: "calendar") {
                            if !isAddingItem {
                                newItem.dueDate = nil
                                newItem.reminderDate = nil
                            }
                        }
                        Button("Today", systemImage: "calendar") {
                            if !isAddingItem {
                                newItem.dueDate = Calendar.current.startOfDay(for: Date())
                            }
                        }
                        Button("Tomorrow", systemImage: "calendar") {
                            if !isAddingItem {
                                newItem.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                            }
                        }
                        Button("Custom…", systemImage: "ellipsis.circle") {
                            if !isAddingItem {
                                showCustomDueDateSheet = true
                            }
                        }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    
                    Spacer()
                }
                .tint(.secondary)
            }
        }
        .sheet(isPresented: Binding(
            get: { showCustomDueDateSheet && !isAddingItem },
            set: { showCustomDueDateSheet = $0 }
        )) {
            CustomDueDateSheet(
                dueDate: $newItem.dueDate,
                reminderEnabled: Binding(
                    get: { newItem.reminderDate != nil },
                    set: { newValue in
                        if newValue {
                            newItem.reminderDate = newItem.dueDate
                        } else {
                            newItem.reminderDate = nil
                        }
                    }
                ),
                reminderMinutesBefore: Binding(
                    get: { newItem.remindBeforeMinutes ?? 5 },
                    set: { newItem.remindBeforeMinutes = $0 }
                ),
                isPresented: Binding(
                    get: { showCustomDueDateSheet && !isAddingItem },
                    set: { showCustomDueDateSheet = $0 }
                )
            )
        }
    }
    
    // MARK: - Actions
    private func delete(item: TodoItem) {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }) else { return }
        modelContext.delete(todo.items![index])
        todo.items!.remove(at: index)
        try? modelContext.save()
    }
    
    private func addNewItem(_ item: TodoItem) {
        isAddingItem = true  // Block all sheet interactions
        
        if todo.items == nil { todo.items = [] }
        todo.items!.append(item)
        try? modelContext.save()
        
        // Reset everything after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            newItem = TodoItem()
            showCustomDueDateSheet = false
            isAddingItem = false
        }
    }
}
