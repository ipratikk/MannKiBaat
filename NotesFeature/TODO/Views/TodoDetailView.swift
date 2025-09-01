import SwiftUI
import SharedModels
import SwiftData

public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    @State private var newItemTitle: String = ""
    @FocusState private var isTitleFocused: Bool
    
    public init(todo: TodoObject) {
        self._todo = Bindable(todo)
    }
    
    // Helper binding to ensure a non-optional array
    private var itemsBinding: Binding<[TodoItem]> {
        Binding(
            get: { todo.items ?? [] },
            set: { todo.items = $0 }
        )
    }
    
    public var body: some View {
        VStack {
            // Editable Todo Title
            TextField("Todo Title", text: $todo.title)
                .font(.largeTitle.bold())
                .padding()
                .focused($isTitleFocused)
                .onAppear {
                    // Focus if it's a new todo
                    if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTitleFocused = true
                        }
                    }
                }
            
            List {
                // Existing Todo Items
                ForEach(itemsBinding, id: \.id) { $item in
                    HStack {
                        Button {
                            item.isCompleted.toggle()
                            item.updatedAt = Date()
                            try? modelContext.save()
                        } label: {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .secondary)
                                .font(.title2)
                        }
                        TextField("Item", text: $item.title)
                            .strikethrough(item.isCompleted, color: .gray)
                            .foregroundColor(item.isCompleted ? .gray : .primary)
                    }
                }
                .onDelete { indexSet in
                    guard var items = todo.items else { return }
                    for i in indexSet {
                        modelContext.delete(items[i])
                        items.remove(at: i)
                    }
                    todo.items = items
                    try? modelContext.save()
                }
                
                // Add New Item
                HStack {
                    TextField("New Item", text: $newItemTitle)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    Button {
                        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let newItem = TodoItem(title: trimmed, parent: todo)
                        if todo.items == nil { todo.items = [] }
                        todo.items!.append(newItem)
                        try? modelContext.save()
                        newItemTitle = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title2)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle(todo.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
