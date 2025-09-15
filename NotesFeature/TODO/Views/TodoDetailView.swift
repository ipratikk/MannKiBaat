import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct TodoDetailView: View {
    @Bindable var todo: TodoObject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TodosViewModel
    
    @FocusState private var isTitleFocused: Bool
    @State private var newItemTitle: String = ""
    @State private var hideCompletedItems: Bool = true
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
    }
    
    private var items: [TodoItem] {
        (todo.items ?? [])
            .filter { hideCompletedItems ? !$0.isCompleted : true }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }
    
    public var body: some View {
        ZStack {
            GradientBackgroundView()
            
            VStack {
                titleField
                itemsList
            }
            .globalDoneToolbar()
            .navigationTitle(todo.title.isEmpty ? "New Todo" : todo.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { if todo.title.isEmpty { isTitleFocused = true } }
            .onDisappear { saveOrFixTitle() }
        }
    }
    
    // MARK: - Title
    private var titleField: some View {
        TextField("Todo Title", text: $todo.title)
            .font(.largeTitle.bold())
            .padding()
            .focused($isTitleFocused)
    }
    
    // MARK: - Items List
    private var itemsList: some View {
        List {
            ForEach(items, id: \.id) { item in
                todoItemRow(item)
            }
            .onDelete { indexSet in
                withAnimation {
                    let currentItems = items
                    for i in indexSet {
                        guard currentItems.indices.contains(i) else { continue }
                        viewModel.deleteItem(currentItems[i], in: modelContext)
                    }
                }
            }
            
            addItemRow
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Single Item Row
    @ViewBuilder
    private func todoItemRow(_ item: TodoItem) -> some View {
        HStack(alignment: .top) {
            Button {
                withAnimation {
                    viewModel.toggleItemCompletion(item, in: modelContext)
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            .padding(.top, 8)
            
            TextField("New Item", text: Binding(
                get: { item.title },
                set: { newValue in
                    item.title = newValue
                    try? modelContext.save()
                }
            ), axis: .vertical)
            .lineLimit(1...)
            .padding(4)
        }
    }
    
    // MARK: - Add New Item Row
    private var addItemRow: some View {
        HStack(alignment: .bottom) {
            TextField("New Item", text: $newItemTitle, axis: .vertical)
                .lineLimit(1...)
                .padding(4)
            
            Button {
                let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                withAnimation {
                    viewModel.addItem(to: todo, title: trimmed, in: modelContext)
                    newItemTitle = ""
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title2)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(role: .destructive) {
                withAnimation {
                    viewModel.removeTodo(todo, in: modelContext)
                    dismiss()
                }
            } label: { Image(systemName: "trash") }
            
            Button {
                withAnimation { hideCompletedItems.toggle() }
            } label: {
                Image(systemName: hideCompletedItems ? "eye.slash" : "eye")
            }
        }
    }
    
    // MARK: - Save/Fix Title
    private func saveOrFixTitle() {
        if todo.title.trimmingCharacters(in: .whitespaces).isEmpty {
            todo.title = "New Todo"
        }
        try? modelContext.save()
    }
}
