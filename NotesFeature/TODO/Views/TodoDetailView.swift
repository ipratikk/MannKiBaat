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
    @State private var hideCompletedItems: Bool = false
    
    public init(todo: TodoObject, viewModel: TodosViewModel) {
        self._todo = Bindable(todo)
        self.viewModel = viewModel
    }
    
    // Pre-filter + sort items
    private var items: [TodoItem] {
        (todo.items ?? [])
            .filter { hideCompletedItems ? !$0.isCompleted : true }
            .sorted {
                // Pinned always first, then incomplete before complete
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned && !$1.isPinned
                }
                return !$0.isCompleted && $1.isCompleted
            }
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
    
    // MARK: - Items List (List with pin/delete)
    private var itemsList: some View {
        List {
            ForEach(items, id: \.id) { item in
                todoItemRow(item)
                    .id(item.id)
                // 👉 Swipe right for pin/unpin
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                item.isPinned.toggle()
                                item.updatedAt = Date()
                                try? modelContext.save()
                            }
                        } label: {
                            Label(item.isPinned ? "Unpin" : "Pin",
                                  systemImage: item.isPinned ? "pin.slash" : "pin")
                        }
                        .tint(.yellow)
                        .labelStyle(.iconOnly)
                    }
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
        .animation(.easeInOut(duration: 0.25), value: items)
    }
    
    // MARK: - Single Item Row
    @ViewBuilder
    private func todoItemRow(_ item: TodoItem) -> some View {
        HStack(alignment: .top) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.toggleItemCompletion(item, in: modelContext)
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isCompleted ? .green : .secondary)
                    .scaleEffect(item.isCompleted ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.25), value: item.isCompleted)
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
            
            Spacer()
            
            // 👉 Show pin icon if pinned
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(45)) // tilted like iOS pin
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.25), value: item.isPinned)
            }
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
                withAnimation(.easeInOut(duration: 0.25)) {
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
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.removeTodo(todo, in: modelContext)
                    dismiss()
                }
            } label: { Image(systemName: "trash") }
            
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    hideCompletedItems.toggle()
                }
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
