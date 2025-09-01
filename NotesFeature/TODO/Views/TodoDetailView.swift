import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    @State private var newItemTitle: String = ""
    @FocusState private var isTitleFocused: Bool
    @ObservedObject var viewModel: TodosViewModel
    @State private var isNewTodo: Bool = false
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
        self._isNewTodo = State(initialValue: todo.title.isEmpty)
    }
    
    private var itemsBinding: Binding<[TodoItem]> {
        Binding(
            get: { todo.items ?? [] },
            set: { todo.items = $0 }
        )
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            VStack {
                TextField("Todo Title", text: $todo.title)
                    .font(.largeTitle.bold())
                    .padding()
                    .focused($isTitleFocused)
                
                List {
                    let sortedItems = itemsBinding.wrappedValue.sorted { !$0.isCompleted && $1.isCompleted }
                    
                    ForEach(sortedItems.indices, id: \.self) { index in
                        let item = sortedItems[index]
                        HStack {
                            Button {
                                Task {
                                    await viewModel.toggleItemCompletion(item, in: modelContext)
                                }
                            } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? .green : .secondary)
                            }
                            TextField("Item", text: Binding(
                                get: { item.title },
                                set: { newValue in item.title = newValue }
                            ))
                        }
                    }
                    .onDelete { indexSet in
                        var items = todo.items ?? []
                        for i in indexSet.sorted(by: >) {
                            modelContext.delete(items[i])
                            items.remove(at: i)
                        }
                        todo.items = items
                        try? modelContext.save()
                    }
                    
                    HStack {
                        TextField("New Item", text: $newItemTitle)
                            .focused($isTitleFocused)
                        Button {
                            let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                // Create a new TodoItem and append to existing todo
                                let newItem = TodoItem(title: trimmed)
                                todo.items?.append(newItem) ?? { todo.items = [newItem] }()
                                try? modelContext.save()
                                newItemTitle = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.title2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(todo.title.isEmpty ? "New Todo" : todo.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if isNewTodo {
                    isTitleFocused = true
                }
            }
            .onDisappear {
                Task {
                    // Ensure a default title if empty
                    if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        todo.title = "New Todo"
                    }
                    
                    // Insert only once if it's new
                    if isNewTodo {
                        modelContext.insert(todo)
                        try? modelContext.save()
                        isNewTodo = false // mark as inserted
                    }
                }
            }
        }
    }
}
