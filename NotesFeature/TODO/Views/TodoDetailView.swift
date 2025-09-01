// TodoDetailView.swift

import SwiftUI
import SharedModels
import SwiftData

public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    
    @State private var newItem = TodoItem()
    @FocusState private var isTitleFocused: Bool
    
    public init(todo: TodoObject) {
        self._todo = Bindable(todo)
    }
    
    private var incompleteItems: [TodoItem] {
        todo.items?.filter { !$0.isCompleted } ?? []
    }
    
    private var completedItems: [TodoItem] {
        todo.items?.filter { $0.isCompleted } ?? []
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
                .onAppear {
                    if todo.title.isEmpty {
                        isTitleFocused = true
                    }
                }
            
            List {
                // Incomplete items
                if let items = todo.items {
                    ForEach(items.indices.filter { !items[$0].isCompleted }, id: \.self) { index in
                        TodoItemRow(item: Binding(
                            get: { todo.items![index] },
                            set: { todo.items![index] = $0 }
                        ), isExpanded: false, toggleExpanded: {})
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(item: todo.items![index])
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                // Completed items
                if !completedItems.isEmpty {
                    Section("Completed") {
                        if let items = todo.items {
                            ForEach(items.indices.filter { items[$0].isCompleted }, id: \.self) { index in
                                TodoItemRow(item: Binding(
                                    get: { todo.items![index] },
                                    set: { todo.items![index] = $0 }
                                ), isExpanded: false, toggleExpanded: {})
                                .swipeActions {
                                    Button(role: .destructive) {
                                        delete(item: todo.items![index])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // New task input
                Section {
                    NewTaskInputView(newItem: $newItem, addAction: addNewItem)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Actions
    
    private func delete(item: TodoItem) {
        guard let index = todo.items?.firstIndex(where: { $0.id == item.id }) else { return }
        modelContext.delete(todo.items![index])
        todo.items!.remove(at: index)
        try? modelContext.save()
    }
    
    private func addNewItem(_ item: TodoItem) {
        if todo.items == nil { todo.items = [] }
        todo.items!.append(item)
        try? modelContext.save()
        newItem = TodoItem()
    }
}
